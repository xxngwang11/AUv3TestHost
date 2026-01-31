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
    @State private var showDiagnostics = false
    
    // Detect device type for adaptive UI
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        #if os(iOS)
        // On iPhone (compact), use NavigationStack for better UX
        // On iPad (regular), use NavigationSplitView
        if horizontalSizeClass == .compact {
            compactLayout
        } else {
            splitViewLayout
        }
        #else
        // macOS always uses split view
        splitViewLayout
        #endif
    }
    
    // MARK: - Compact Layout (iPhone)
    
    #if os(iOS)
    private var compactLayout: some View {
        NavigationStack {
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
                List(scanner.plugins, id: \.name) { plugin in
                    Button {
                        selectedPlugin = plugin
                    } label: {
                        PluginRow(plugin: plugin)
                    }
                }
                .listStyle(.inset)
                
                // 扫描按钮
                Button("Refresh Plugins") {
                    scanner.scan()
                }
                .padding()
            }
            .navigationTitle("AUv3 Plugins")
            .navigationDestination(item: $selectedPlugin) { plugin in
                PluginDetailView(
                    plugin: plugin,
                    engine: engine,
                    loadOutOfProcess: loadOutOfProcess
                )
                .navigationTitle(plugin.name)
                .navigationBarTitleDisplayMode(.inline)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            showDiagnostics = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        
                        Button {
                            showMetricsHistory = true
                        } label: {
                            Image(systemName: "chart.bar.doc.horizontal")
                        }
                    }
                }
            }
            .sheet(isPresented: $showMetricsHistory) {
                MetricsHistoryView()
            }
            .sheet(isPresented: $showDiagnostics) {
                DiagnosticsView(scanner: scanner)
            }
            .onAppear {
                scanner.scan()
            }
        }
    }
    #endif
    
    // MARK: - Split View Layout (iPad/macOS)
    
    private var splitViewLayout: some View {
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
            #if os(macOS)
            .frame(minWidth: 250)
            #endif
            
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
                HStack {
                    Button {
                        showDiagnostics = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    
                    Button {
                        showMetricsHistory = true
                    } label: {
                        Image(systemName: "chart.bar.doc.horizontal")
                    }
                }
            }
        }
        .sheet(isPresented: $showMetricsHistory) {
            MetricsHistoryView()
        }
        .sheet(isPresented: $showDiagnostics) {
            DiagnosticsView(scanner: scanner)
        }
        .onAppear {
            scanner.scan()
        }
    }
}