import AVFoundation
import AudioToolbox

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
    
    public var plugins: [AVAudioUnitComponent] = []
    public var isScanning = false
    public var selectedType: AudioUnitType = .effect
    
    public init() {}
    
    /// 扫描指定类型的插件
    public func scan(type: AudioUnitType? = nil) {
        isScanning = true
        
        let typeToScan = type ?? selectedType
        
        let description = AudioComponentDescription(
            componentType: typeToScan.componentType,
            componentSubType: 0,
            componentManufacturer: 0,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        
        plugins = AVAudioUnitComponentManager.shared().components(matching: description)
            .sorted { $0.name < $1.name }
        
        isScanning = false
    }
    
    /// 扫描所有类型的插件
    public func scanAll() -> [AudioUnitType: [AVAudioUnitComponent]] {
        var result: [AudioUnitType: [AVAudioUnitComponent]] = [:]
        
        for type in AudioUnitType.allCases {
            let description = AudioComponentDescription(
                componentType: type.componentType,
                componentSubType: 0,
                componentManufacturer: 0,
                componentFlags: 0,
                componentFlagsMask: 0
            )
            result[type] = AVAudioUnitComponentManager.shared().components(matching: description)
        }
        
        return result
    }
}