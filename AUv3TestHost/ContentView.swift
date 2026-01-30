import SwiftUI
import AVFoundation
import CoreAudioKit

struct ContentView: View {
    @State private var scanner = PluginScanner()
    @State private var engine = AudioEngine()
    @State private var metricsManager = MetricsManager.shared
    
    @State private var selectedPlugin: AVAudioUnitComponent?
    @State private var loadOutOfProcess = true
    @State private var showMetricsHistory = false
    
    var body: some View {
        NavigationSplitView {
            // 左侧：插件列表
            VStack {
                // 插件类型选择
                Picker("Type", selection: $scanner.selectedType) {
                    ForEach(AudioUnitType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: scanner.selectedType) { _, _ in
                    scanner.scan()
                }
                
                // 加载选项
                Toggle("Out-of-Process", isOn: $loadOutOfProcess)
                    .padding(.horizontal)
                
                // 插件列表
                List(scanner.plugins, id: \.name, selection: $selectedPlugin) { plugin in
                    PluginRow(plugin: plugin)
                }
                .listStyle(.inset)
                
                // 扫描按钮
                Button("Refresh Plugins") {
                    scanner.scan()
                }
                .padding()
            }
            .navigationTitle("AUv3 Plugins")
            .frame(minWidth: 250)
            
        } detail: {
            // 右侧：插件详情和性能指标
            if let plugin = selectedPlugin {
                PluginDetailView(
                    plugin: plugin,
                    engine: engine,
                    loadOutOfProcess: loadOutOfProcess
                )
            } else {
                ContentUnavailableView(
                    "Select a Plugin",
                    systemImage: "slider.horizontal.3",
                    description: Text("Choose a plugin from the list to load and test")
                )
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showMetricsHistory = true
                } label: {
                    Image(systemName: "chart.bar.doc.horizontal")
                }
            }
        }
        .sheet(isPresented: $showMetricsHistory) {
            MetricsHistoryView()
        }
        .onAppear {
            scanner.scan()
        }
    }
}