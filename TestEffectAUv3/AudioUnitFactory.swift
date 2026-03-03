import AVFoundation

/// 工厂函数（后备路径 —— 当系统不通过 AUAudioUnitFactory 协议加载时使用）
@_cdecl("TestEffectAudioUnitFactory")
public func TestEffectAudioUnitFactory(componentDescription: AudioComponentDescription) -> AUAudioUnit? {
    return try? TestEffectAudioUnit(componentDescription: componentDescription, options: [])
}
