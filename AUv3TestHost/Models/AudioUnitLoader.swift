import AVFoundation
import AudioToolbox
import os

/// AUv3 插件类型
public enum AudioUnitType: String, CaseIterable, Identifiable {
    case effect = "Effect"
    case instrument = "Instrument"
    case midiProcessor = "MIDI Processor"
    case musicEffect = "Music Effect"
    case generator = "Generator"
    
    public var id: String { rawValue }
    
    public var componentType: OSType {
        switch self {
        case .effect: return kAudioUnitType_Effect
        case .instrument: return kAudioUnitType_MusicDevice
        case .midiProcessor: return kAudioUnitType_MIDIProcessor
        case .musicEffect: return kAudioUnitType_MusicEffect
        case .generator: return kAudioUnitType_Generator
        }
    }
    
    public var fourCharCode: String {
        switch self {
        case .effect: return "aufx"
        case .instrument: return "aumu"
        case .midiProcessor: return "aumi"
        case .musicEffect: return "aumf"
        case .generator: return "augn"
        }
    }
}

/// 插件扫描器
@MainActor
@Observable
public class PluginScanner {
    
    private let log = Logger(subsystem: "com.test.AUv3TestHost", category: "PluginScanner")
    
    public var plugins: [AVAudioUnitComponent] = []
    public var isScanning = false
    public var selectedType: AudioUnitType = .effect
    public var lastScanError: String?
    public var scanDiagnostics: [String] = []
    
    public init() {}
    
    /// 扫描指定类型的插件
    public func scan(type: AudioUnitType? = nil) {
        isScanning = true
        lastScanError = nil
        scanDiagnostics.removeAll()
        
        let typeToScan = type ?? selectedType
        
        log.info("Starting plugin scan for type: \(typeToScan.rawValue)")
        
        #if os(iOS)
        // iOS-specific diagnostics
        log.info("Running on iOS - checking audio component manager status")
        scanDiagnostics.append("Platform: iOS")
        
        // Check if we have necessary permissions
        let audioSession = AVAudioSession.sharedInstance()
        log.info("Audio session category: \(audioSession.category.rawValue)")
        log.info("Audio session mode: \(audioSession.mode.rawValue)")
        scanDiagnostics.append("Audio Session: \(audioSession.category.rawValue)")
        #else
        scanDiagnostics.append("Platform: macOS")
        #endif
        
        let description = AudioComponentDescription(
            componentType: typeToScan.componentType,
            componentSubType: 0,
            componentManufacturer: 0,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        
        let manager = AVAudioUnitComponentManager.shared()
        let foundPlugins = manager.components(matching: description)
        
        log.info("Found \(foundPlugins.count) plugins of type \(typeToScan.rawValue)")
        scanDiagnostics.append("Found: \(foundPlugins.count) plugins")
        
        if foundPlugins.isEmpty {
            log.warning("No plugins found - this could be due to:")
            log.warning("  1. No AUv3 plugins installed")
            log.warning("  2. Sandbox restrictions (iOS)")
            log.warning("  3. Audio session not properly configured")
            scanDiagnostics.append("⚠️ No plugins found")
            
            #if os(iOS)
            lastScanError = "No AUv3 plugins found. On iOS, ensure:\n1. AUv3 plugins are installed\n2. Audio permissions are granted\n3. App has proper entitlements"
            #else
            lastScanError = "No AUv3 plugins found. Ensure AUv3 plugins are installed in the system."
            #endif
        } else {
            // Log details about found plugins
            for plugin in foundPlugins {
                log.debug("Plugin: \(plugin.name) by \(plugin.manufacturerName)")
                log.debug("  - Version: \(plugin.versionString ?? "unknown")")
                log.debug("  - Type: \(plugin.typeName)")
            }
        }
        
        plugins = foundPlugins.sorted { $0.name < $1.name }
        
        isScanning = false
    }
    
    /// 扫描所有类型的插件
    public func scanAll() -> [AudioUnitType: [AVAudioUnitComponent]] {
        var result: [AudioUnitType: [AVAudioUnitComponent]] = [:]
        
        log.info("Scanning all plugin types")
        
        for type in AudioUnitType.allCases {
            let description = AudioComponentDescription(
                componentType: type.componentType,
                componentSubType: 0,
                componentManufacturer: 0,
                componentFlags: 0,
                componentFlagsMask: 0
            )
            
            let foundPlugins = AVAudioUnitComponentManager.shared().components(matching: description)
            result[type] = foundPlugins
            
            log.info("Type \(type.rawValue): found \(foundPlugins.count) plugins")
        }
        
        return result
    }
    
    /// 获取诊断信息
    public func getDiagnostics() -> String {
        var diagnostics = "=== AUv3 Plugin Scanner Diagnostics ===\n\n"
        
        diagnostics += scanDiagnostics.joined(separator: "\n")
        diagnostics += "\n\n"
        
        if let error = lastScanError {
            diagnostics += "Last Error:\n\(error)\n\n"
        }
        
        diagnostics += "Total Plugins Found: \(plugins.count)\n"
        
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        diagnostics += "\nAudio Session Info:\n"
        diagnostics += "  - Category: \(audioSession.category.rawValue)\n"
        diagnostics += "  - Mode: \(audioSession.mode.rawValue)\n"
        diagnostics += "  - Sample Rate: \(audioSession.sampleRate) Hz\n"
        diagnostics += "  - IO Buffer Duration: \(audioSession.ioBufferDuration * 1000) ms\n"
        #endif
        
        return diagnostics
    }
}