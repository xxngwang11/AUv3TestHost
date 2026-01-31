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
            .navigationTitle("Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
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
            Text("System Information")
                .font(.headline)
            
            #if os(iOS)
            InfoRow(label: "Platform", value: "iOS")
            InfoRow(label: "Device", value: UIDevice.current.model)
            InfoRow(label: "OS Version", value: UIDevice.current.systemVersion)
            #else
            InfoRow(label: "Platform", value: "macOS")
            #endif
            
            InfoRow(label: "App Version", value: "1.0")
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var scannerDiagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plugin Scanner")
                .font(.headline)
            
            InfoRow(label: "Selected Type", value: scanner.selectedType.rawValue)
            InfoRow(label: "Plugins Found", value: "\(scanner.plugins.count)")
            
            if !scanner.scanDiagnostics.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan Diagnostics:")
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
                Text("Error: \(error)")
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
            Text("Audio Session")
                .font(.headline)
            
            let audioSession = AVAudioSession.sharedInstance()
            
            InfoRow(label: "Category", value: audioSession.category.rawValue)
            InfoRow(label: "Mode", value: audioSession.mode.rawValue)
            InfoRow(label: "Sample Rate", value: "\(Int(audioSession.sampleRate)) Hz")
            InfoRow(label: "Buffer Duration", value: String(format: "%.2f ms", audioSession.ioBufferDuration * 1000))
            InfoRow(label: "Input Channels", value: "\(audioSession.inputNumberOfChannels)")
            InfoRow(label: "Output Channels", value: "\(audioSession.outputNumberOfChannels)")
            
            // Current route
            let currentRoute = audioSession.currentRoute
            if !currentRoute.outputs.isEmpty {
                Text("Output: \(currentRoute.outputs.first?.portName ?? "Unknown")")
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
            Text("Troubleshooting Tips")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                RecommendationRow(
                    icon: "checkmark.circle.fill",
                    text: "Ensure AUv3 plugins are installed from the App Store",
                    color: .blue
                )
                
                #if os(iOS)
                RecommendationRow(
                    icon: "mic.fill",
                    text: "Grant microphone permission in Settings → Privacy",
                    color: .orange
                )
                
                RecommendationRow(
                    icon: "speaker.wave.2.fill",
                    text: "Check audio session is properly configured (see above)",
                    color: .green
                )
                #endif
                
                RecommendationRow(
                    icon: "arrow.clockwise",
                    text: "Try refreshing the plugin list after installing new plugins",
                    color: .purple
                )
                
                if scanner.plugins.isEmpty {
                    RecommendationRow(
                        icon: "exclamationmark.triangle.fill",
                        text: "No plugins found - install AUv3 plugins to test",
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
