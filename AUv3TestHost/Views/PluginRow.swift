import SwiftUI
import AVFoundation

struct PluginRow: View {
    let plugin: AVAudioUnitComponent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(plugin.name)
                .font(.headline)
            
            Text(plugin.manufacturerName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(formatComponentDescription(plugin.audioComponentDescription))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatComponentDescription(_ desc: AudioComponentDescription) -> String {
        let type = fourCharString(desc.componentType)
        let subType = fourCharString(desc.componentSubType)
        let manufacturer = fourCharString(desc.componentManufacturer)
        return "\(type) / \(subType) / \(manufacturer)"
    }
    
    private func fourCharString(_ value: OSType) -> String {
        let chars: [Character] = [
            Character(UnicodeScalar((value >> 24) & 0xFF)!),
            Character(UnicodeScalar((value >> 16) & 0xFF)!),
            Character(UnicodeScalar((value >> 8) & 0xFF)!),
            Character(UnicodeScalar(value & 0xFF)!)
        ]
        return String(chars)
    }
}