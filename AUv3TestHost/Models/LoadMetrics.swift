import Foundation
import os

/// 插件加载性能指标
public struct PluginLoadMetrics: Identifiable {
    public let id = UUID()
    public let pluginName: String
    public let timestamp: Date
    
    // 各阶段耗时 (ms)
    public var findComponentTime: Double = 0
    public var instantiateTime: Double = 0
    public var connectAudioGraphTime: Double = 0
    public var allocateResourcesTime: Double = 0
    public var loadViewControllerTime: Double = 0
    public var totalTime: Double = 0
    
    // 加载选项
    public var loadedOutOfProcess: Bool = true
    
    // 错误信息
    public var errorMessage: String?
    
    public var summary: String {
        return String(format: "Total: %.2f ms (Instantiate: %.2f ms)", totalTime, instantiateTime)
    }
}

/// 性能指标管理器
@MainActor
public class MetricsManager: ObservableObject {
    public static let shared = MetricsManager()
    
    @Published public var history: [PluginLoadMetrics] = []
    @Published public var currentMetrics: PluginLoadMetrics?
    
    private let log = Logger(subsystem: "com.test.AUv3TestHost", category: "Metrics")
    
    private init() {}
    
    public func record(_ metrics: PluginLoadMetrics) {
        currentMetrics = metrics
        history.insert(metrics, at: 0)
        
        // 保留最近 50 条记录
        if history.count > 50 {
            history = Array(history.prefix(50))
        }
        
        log.info("""
        
        ╔═══════════════════════════════════════════════════════════╗
        ║  Plugin: \(metrics.pluginName)
        ╠═══════════════════════════════════════════════════════════╣
        ║  Find Component:       \(String(format: "%8.2f", metrics.findComponentTime)) ms
        ║  Instantiate:          \(String(format: "%8.2f", metrics.instantiateTime)) ms
        ║  Connect Audio Graph:  \(String(format: "%8.2f", metrics.connectAudioGraphTime)) ms
        ║  Allocate Resources:   \(String(format: "%8.2f", metrics.allocateResourcesTime)) ms
        ║  Load ViewController:  \(String(format: "%8.2f", metrics.loadViewControllerTime)) ms
        ╠═══════════════════════════════════════════════════════════╣
        ║  🚀 Total:             \(String(format: "%8.2f", metrics.totalTime)) ms
        ║  Mode: \(metrics.loadedOutOfProcess ? "Out-of-Process" : "In-Process")
        ╚═══════════════════════════════════════════════════════════╝
        
        """)
    }
    
    public func clearHistory() {
        history.removeAll()
        currentMetrics = nil
    }
}