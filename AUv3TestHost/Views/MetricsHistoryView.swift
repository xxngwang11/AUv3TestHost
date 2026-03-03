import SwiftUI

struct MetricsHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var metricsManager = MetricsManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(metricsManager.history) { metrics in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(metrics.pluginName)
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f ms", metrics.totalTime))
                                .font(.title3)
                                .bold()
                                .foregroundColor(colorForTime(metrics.totalTime))
                        }
                        
                        HStack {
                            Text(metrics.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(metrics.loadedOutOfProcess ? "进程外" : "进程内")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        // 详细数据
                        HStack(spacing: 16) {
                            miniMetric("实例化", metrics.instantiateTime)
                            miniMetric("连接", metrics.connectAudioGraphTime)
                            miniMetric("分配", metrics.allocateResourcesTime)
                            miniMetric("界面", metrics.loadViewControllerTime)
                        }
                        .font(.caption2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("加载历史")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button("清除") {
                        metricsManager.clearHistory()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
    
    private func miniMetric(_ label: String, _ value: Double) -> some View {
        VStack {
            Text(String(format: "%.1f", value))
                .monospacedDigit()
            Text(label)
                .foregroundColor(.secondary)
        }
    }
    
    private func colorForTime(_ time: Double) -> Color {
        if time < 200 { return .green }
        if time < 500 { return .orange }
        return .red
    }
}