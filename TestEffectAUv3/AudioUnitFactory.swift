import AVFoundation

/// Factory function for creating the Audio Unit
@_cdecl("TestEffectAudioUnitFactory")
public func TestEffectAudioUnitFactory(componentDescription: AudioComponentDescription) -> AUAudioUnit? {
    return try? TestEffectAudioUnit(componentDescription: componentDescription, options: [])
}
