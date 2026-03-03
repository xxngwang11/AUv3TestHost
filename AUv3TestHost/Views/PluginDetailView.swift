import SwiftUI
import AVFoundation
import CoreAudioKit

struct PluginDetailView: View {
    let plugin: AVAudioUnitComponent
    @Bindable var engine: AudioEngine
    
    @State private var currentMetrics: PluginLoadMetrics?
    @State private var isLoading = false
    @State private var loadCount = 0
    // FourCC "appl" (hex: 0x6170706C) used by Apple's built-in Audio Units.
    private let appleManufacturerCode: OSType = 0x6170706C
    
    private var isAppleSystemPlugin: Bool {
        plugin.audioComponentDescription.componentManufacturer == appleManufacturerCode
    }
    
    private var noPluginUIDescription: String {
        if engine.currentAudioUnit == nil {
            return "加载插件以查看其界面。"
        }
        if isAppleSystemPlugin {
            return "此插件未向宿主提供自定义界面。部分 Apple 内置效果器（如 AUBandpassFilter 和 AUDelay）仅支持参数控制。"
        }
        return "此插件未向宿主提供自定义界面。部分插件仅支持参数控制。"
    }
    
    private var metricsOverheadExplanation: String {
        "各阶段耗时之和可能不等于总加载时间，总时间还包括初始化操作和异步回调开销。"
    }
    
    private func stageSum(for metrics: PluginLoadMetrics) -> Double {
        metrics.instantiateTime + metrics.connectAudioGraphTime + metrics.allocateResourcesTime + metrics.loadViewControllerTime
    }
    
    private func otherOverhead(for metrics: PluginLoadMetrics) -> Double {
        max(0, metrics.totalTime - stageSum(for: metrics))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 插件信息头
            pluginHeader
            
            Divider()
            
            // 性能指标
            if let metrics = currentMetrics {
                metricsSection(metrics)
            }
            
            Divider()
            
            // 插件 UI
            pluginUISection
            
            Spacer()
            
            // 控制栏
            controlBar
        }
        .onChange(of: plugin.name) { _, _ in
            currentMetrics = nil
        }
    }
    
    // MARK: - 插件信息头
    
    private var pluginHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.name)
                    .font(.title)
                    .bold()
                
                Text(plugin.manufacturerName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isAppleSystemPlugin {
                    Text("系统内置插件 (Apple)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text("版本：\(plugin.versionString)")
  	                    .font(.caption)
  	                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 加载按钮
            Button {
                Task {
                    await loadPlugin()
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Label("加载", systemImage: "play.circle.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            
            // 批量测试按钮
            Button {
                Task {
                    await runBenchmark(times: 5)
                }
            } label: {
                Label("基准测试 x5", systemImage: "gauge.with.dots.needle.67percent")
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)
        }
        .padding()
    }
    
    // MARK: - 性能指标
    
    private func metricsSection(_ metrics: PluginLoadMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("加载性能")
                    .font(.headline)
                
                Spacer()
                
                if metrics.isColdStart {
                    Text("冷启动")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Text(metrics.loadedOutOfProcess ? "进程外" : "进程内")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(metrics.loadedOutOfProcess ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
            
            if let errorMessage = metrics.errorMessage, engine.currentAudioUnit == nil {
                HStack(alignment: .top) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // 指标条形图
            VStack(spacing: 8) {
                MetricBar(label: "实例化", value: metrics.instantiateTime, maxValue: metrics.totalTime, color: .blue)
                MetricBar(label: "连接音频图", value: metrics.connectAudioGraphTime, maxValue: metrics.totalTime, color: .green)
                MetricBar(label: "分配资源", value: metrics.allocateResourcesTime, maxValue: metrics.totalTime, color: .orange)
                MetricBar(label: "加载视图控制器", value: metrics.loadViewControllerTime, maxValue: metrics.totalTime, color: .purple)
            }
            
            Divider()
            
            // 总时间
            HStack {
                Text("总加载时间")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.2f ms", metrics.totalTime))
                    .font(.title2)
                    .bold()
                    .foregroundColor(metrics.totalTime < 200 ? .green : (metrics.totalTime < 500 ? .orange : .red))
            }
            
            Text(metricsOverheadExplanation)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("阶段耗时之和: \(String(format: "%.2f", stageSum(for: metrics))) ms，其他开销: \(String(format: "%.2f", otherOverhead(for: metrics))) ms")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if metrics.isColdStart {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("首次进程外加载（冷启动）需要启动 XPC 宿主进程，耗时约 1-2 秒属于正常现象。后续加载将复用已运行的进程，速度会显著提升。系统内置插件不受此影响，因为它们始终以进程内方式加载。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !metrics.loadedOutOfProcess && isAppleSystemPlugin {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("此插件为 Apple 系统内置 v2 Audio Unit，已自动切换为进程内加载，无冷启动延迟。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .padding()
    }
    
    // MARK: - 插件 UI
    
    private var pluginUISection: some View {
        Group {
            if let viewController = engine.currentViewController {
                AUViewControllerRepresentable(viewController: viewController)
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                    .padding()
            } else if let audioUnit = engine.currentAudioUnit,
                      let parameterTree = audioUnit.auAudioUnit.parameterTree,
                      !parameterTree.allParameters.isEmpty {
                // 插件未提供自定义界面，使用通用参数控制
                GenericParameterView(parameterTree: parameterTree)
                    .padding()
            } else {
                ContentUnavailableView(
                    "无插件界面",
                    systemImage: "rectangle.dashed",
                    description: Text(noPluginUIDescription)
                )
                .frame(height: 200)
            }
        }
    }
    
    // MARK: - 控制栏
    
    private var controlBar: some View {
        VStack(spacing: 8) {
            // Info hint for effect plugins
            if let audioUnit = engine.currentAudioUnit,
               audioUnit.auAudioUnit.componentDescription.componentType == kAudioUnitType_Effect ||
               audioUnit.auAudioUnit.componentDescription.componentType == kAudioUnitType_MusicEffect {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("正在通过效果链播放测试音频")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            HStack {
                Button {
                    if engine.isPlaying {
                        engine.stopPlaying()
                    } else {
                        engine.startPlaying()
                    }
                } label: {
                    Image(systemName: engine.isPlaying ? "stop.fill" : "play.fill")
                    Text(engine.isPlaying ? "停止" : "播放测试音频")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                if loadCount > 0 {
                    Text("已加载 \(loadCount) 次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.secondary.opacity(0.1))
    }
    
    // MARK: - 加载逻辑
    
    private func loadPlugin() async {
        isLoading = true
        defer { isLoading = false }
        
        let metrics = await engine.loadPlugin(
            component: plugin,
            outOfProcess: true
        )
        currentMetrics = metrics
        if engine.currentAudioUnit != nil {
            loadCount += 1
        }
    }
    
    private func runBenchmark(times: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        var totalTime: Double = 0
        var successfulLoadCount = 0
        
        for _ in 0..<times {
            let metrics = await engine.loadPlugin(
                component: plugin,
                outOfProcess: true
            )
            if engine.currentAudioUnit != nil {
                totalTime += metrics.totalTime
                loadCount += 1
                successfulLoadCount += 1
                currentMetrics = metrics
            }
            
            // 等待一下再进行下一次
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        }
        
        guard successfulLoadCount > 0 else {
            print("Benchmark complete: 0 successful out-of-process loads")
            return
        }
        
        let avgTime = totalTime / Double(successfulLoadCount)
        print("Benchmark complete: Average load time = \(String(format: "%.2f", avgTime)) ms")
    }
}
