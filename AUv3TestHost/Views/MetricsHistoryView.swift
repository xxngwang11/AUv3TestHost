import SwiftUI

struct MetricsHistoryView: View {
    @Environment(\.
    dismiss) private var dismiss
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
                            
                            Text(metrics.loadedOutOfProcess ? "OOP" : "IP")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        // 详细数据
                        HStack(spacing: 16) {
                            miniMetric("Init", metrics.instantiateTime)
                            miniMetric("Connect", metrics.connectAudioGraphTime)
                            miniMetric("Alloc", metrics.allocateResourcesTime)
                            miniMetric("UI", metrics.loadViewControllerTime)
                        }
                        .font(.caption2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Load History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button("Clear") {
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