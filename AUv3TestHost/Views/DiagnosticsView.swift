import SwiftUI
import AVFoundation
import os

/// Diagnostic view to show system information and help debug iOS issues
struct DiagnosticsView: View {
    let scanner: PluginScanner
    @State private var diagnosticsText: String = ""
    
    private let log = Logger(subsystem: "com.test.AUv3TestHost", category: "Diagnostics")
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // System Info
                    systemInfoSection
                    
                    Divider()
                    
                    // Plugin Scanner Diagnostics
                    scannerDiagnosticsSection
                    
                    Divider()
                    
                    // Audio Session Info
                    #if os(iOS)
                    audioSessionSection
                    #endif
                    
                    Divider()
                    
                    // Recommendations
                    recommendationsSection
                }
                .padding()
            }
            .navigationTitle("诊断信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刷新") {
                        updateDiagnostics()
                    }
                }
            }
            .onAppear {
                updateDiagnostics()
            }
        }
    }
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("系统信息")
                .font(.headline)
            
            #if os(iOS)
            InfoRow(label: "平台", value: "iOS")
            InfoRow(label: "设备", value: UIDevice.current.model)
            InfoRow(label: "系统版本", value: UIDevice.current.systemVersion)
            #else
            InfoRow(label: "平台", value: "macOS")
            #endif
            
            InfoRow(label: "应用版本", value: "1.0")
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var scannerDiagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("插件扫描器")
                .font(.headline)
            
            InfoRow(label: "选中类型", value: scanner.selectedType.rawValue)
            InfoRow(label: "已发现插件", value: "\(scanner.plugins.count)")
            
            if !scanner.scanDiagnostics.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("扫描诊断:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(scanner.scanDiagnostics, id: \.self) { diagnostic in
                        Text("• \(diagnostic)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let error = scanner.lastScanError {
                Text("错误: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    #if os(iOS)
    private var audioSessionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("音频会话")
                .font(.headline)
            
            let audioSession = AVAudioSession.sharedInstance()
            
            InfoRow(label: "类别", value: audioSession.category.rawValue)
            InfoRow(label: "模式", value: audioSession.mode.rawValue)
            InfoRow(label: "采样率", value: "\(Int(audioSession.sampleRate)) Hz")
            InfoRow(label: "缓冲时长", value: String(format: "%.2f ms", audioSession.ioBufferDuration * 1000))
            InfoRow(label: "输入声道", value: "\(audioSession.inputNumberOfChannels)")
            InfoRow(label: "输出声道", value: "\(audioSession.outputNumberOfChannels)")
            
            // Current route
            let currentRoute = audioSession.currentRoute
            if !currentRoute.outputs.isEmpty {
                Text("输出: \(currentRoute.outputs.first?.portName ?? "未知")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    #endif
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("故障排除提示")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                RecommendationRow(
                    icon: "checkmark.circle.fill",
                    text: "请确保已从 App Store 安装 AUv3 插件",
                    color: .blue
                )
                
                #if os(iOS)
                RecommendationRow(
                    icon: "mic.fill",
                    text: "请在 设置 → 隐私 中授予麦克风权限",
                    color: .orange
                )
                
                RecommendationRow(
                    icon: "speaker.wave.2.fill",
                    text: "请检查音频会话配置是否正确（见上方）",
                    color: .green
                )
                #endif
                
                RecommendationRow(
                    icon: "arrow.clockwise",
                    text: "安装新插件后请尝试刷新插件列表",
                    color: .purple
                )
                
                if scanner.plugins.isEmpty {
                    RecommendationRow(
                        icon: "exclamationmark.triangle.fill",
                        text: "未发现插件 - 请安装 AUv3 插件以进行测试",
                        color: .red
                    )
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func updateDiagnostics() {
        diagnosticsText = scanner.getDiagnostics()
        log.info("Diagnostics updated")
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .bold()
        }
    }
}

struct RecommendationRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    DiagnosticsView(scanner: PluginScanner())
}
