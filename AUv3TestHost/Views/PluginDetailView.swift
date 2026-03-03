import SwiftUI
import AVFoundation
import CoreAudioKit

struct PluginDetailView: View {
    let plugin: AVAudioUnitComponent
    @Bindable var engine: AudioEngine
    let loadOutOfProcess: Bool
    
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
            return "Load a plugin to see its interface."
        }
        if isAppleSystemPlugin {
            return "This plugin did not provide a custom UI to the host. Some Apple built-in effects, such as AUBandpassFilter and AUDelay, are parameter-only."
        }
        return "This plugin did not provide a custom UI to the host. Some plugins are parameter-only."
    }
    
    private var metricsOverheadExplanation: String {
        "Stage sum may not equal total load time. Total also includes setup operations and async callback overhead."
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
                    Text("System built-in plugin (Apple)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text("Version: \(plugin.versionString)")
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
                    Label("Load", systemImage: "play.circle.fill")
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
                Label("Benchmark x5", systemImage: "gauge.with.dots.needle.67percent")
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
                Text("Load Performance")
                    .font(.headline)
                
                Spacer()
                
                Text(metrics.loadedOutOfProcess ? "Out-of-Process" : "In-Process")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(metrics.loadedOutOfProcess ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
            
            // Show fallback/error info
            if metrics.retriedInProcess {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Out-of-process failed, loaded in-process as fallback")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
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
                MetricBar(label: "Instantiate", value: metrics.instantiateTime, maxValue: metrics.totalTime, color: .blue)
                MetricBar(label: "Connect Graph", value: metrics.connectAudioGraphTime, maxValue: metrics.totalTime, color: .green)
                MetricBar(label: "Allocate Resources", value: metrics.allocateResourcesTime, maxValue: metrics.totalTime, color: .orange)
                MetricBar(label: "Load ViewController", value: metrics.loadViewControllerTime, maxValue: metrics.totalTime, color: .purple)
            }
            
            Divider()
            
            // 总时间
            HStack {
                Text("Total Load Time")
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
            Text("Stage sum: \(String(format: "%.2f", stageSum(for: metrics))) ms, other overhead: \(String(format: "%.2f", otherOverhead(for: metrics))) ms")
                .font(.caption)
                .foregroundColor(.secondary)
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
            } else {
                ContentUnavailableView(
                    "No Plugin UI",
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
                    Text("Playing test audio through the effect chain")
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
                    Text(engine.isPlaying ? "Stop" : "Play Test Audio")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                if loadCount > 0 {
                    Text("Loaded \(loadCount) time(s)")
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
            outOfProcess: loadOutOfProcess
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
                outOfProcess: loadOutOfProcess
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
