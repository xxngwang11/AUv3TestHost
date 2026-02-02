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
                
                Text("Version: \(plugin.versionString)")
 	                    .font(.caption)
 	                    .foregroundColor(.secondary)
                }
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
                    description: Text("Load a plugin to see its interface")
                )
                .frame(height: 200)
            }
        }
    }
    
    // MARK: - 控制栏
    
    private var controlBar: some View {
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
        .padding()
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
        loadCount += 1
    }
    
    private func runBenchmark(times: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        var totalTime: Double = 0
        
        for _ in 0..<times {
            let metrics = await engine.loadPlugin(
                component: plugin,
                outOfProcess: loadOutOfProcess
            )
            totalTime += metrics.totalTime
            loadCount += 1
            
            // 等待一下再进行下一次
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        }
        
        let avgTime = totalTime / Double(times)
        print("Benchmark complete: Average load time = \(String(format: "%.2f", avgTime)) ms")
    }
}
