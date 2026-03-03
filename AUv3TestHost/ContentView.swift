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
                Picker("类型", selection: $scanner.selectedType) {
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
                Toggle("进程外加载", isOn: $loadOutOfProcess)
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
                Button("刷新插件列表") {
                    scanner.scan()
                }
                .padding()
            }
            .navigationTitle("AUv3 插件")
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
                Picker("类型", selection: $scanner.selectedType) {
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
                Toggle("进程外加载", isOn: $loadOutOfProcess)
                    .padding(.horizontal)
                
                // 插件列表
                List(scanner.plugins, id: \.name, selection: $selectedPlugin) { plugin in
                    PluginRow(plugin: plugin)
                }
                .listStyle(.inset)
                
                // 扫描按钮
                Button("刷新插件列表") {
                    scanner.scan()
                }
                .padding()
            }
            .navigationTitle("AUv3 插件")
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
                    "请选择插件",
                    systemImage: "slider.horizontal.3",
                    description: Text("从列表中选择一个插件进行加载和测试")
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