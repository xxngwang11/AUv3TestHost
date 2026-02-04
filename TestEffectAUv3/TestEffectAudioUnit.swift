import AVFoundation
import CoreAudioKit
import os

/// Main Audio Unit class implementing the Test Effect
public class TestEffectAudioUnit: AUAudioUnit {
    
    private let log = Logger(subsystem: "com.test.TestEffectAUv3", category: "AudioUnit")
    
    // Audio format
    private var inputBus: AUAudioUnitBus
    private var outputBus: AUAudioUnitBus
    private var inputBusArray: AUAudioUnitBusArray
    private var outputBusArray: AUAudioUnitBusArray
    
    // Parameters
    private var gainParameter: AUParameter!
    private var bypassParameter: AUParameter!
    
    // DSP state
    private var gain: Float = 1.0
    private var bypass: Bool = false
    
    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {
        
        // Create default format
        let defaultFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        
        // Create input/output busses
        inputBus = try AUAudioUnitBus(format: defaultFormat)
        outputBus = try AUAudioUnitBus(format: defaultFormat)
        
        inputBusArray = AUAudioUnitBusArray(audioUnit: nil, busType: .input, busses: [inputBus])
        outputBusArray = AUAudioUnitBusArray(audioUnit: nil, busType: .output, busses: [outputBus])
        
        try super.init(componentDescription: componentDescription, options: options)
        
        // Setup parameters
        setupParameterTree()
        
        log.info("TestEffectAudioUnit initialized")
    }
    
    private func setupParameterTree() {
        // Create Gain parameter (0.0 to 2.0, default 1.0)
        gainParameter = AUParameterTree.createParameter(
            withIdentifier: "gain",
            name: "Gain",
            address: 0,
            min: 0.0,
            max: 2.0,
            unit: .linearGain,
            unitName: nil,
            flags: [.flag_IsReadable, .flag_IsWritable],
            valueStrings: nil,
            dependentParameters: nil
        )
        gainParameter.value = 1.0
        
        // Create Bypass parameter (0 = off, 1 = on)
        bypassParameter = AUParameterTree.createParameter(
            withIdentifier: "bypass",
            name: "Bypass",
            address: 1,
            min: 0,
            max: 1,
            unit: .boolean,
            unitName: nil,
            flags: [.flag_IsReadable, .flag_IsWritable],
            valueStrings: nil,
            dependentParameters: nil
        )
        bypassParameter.value = 0
        
        // Create parameter tree
        parameterTree = AUParameterTree.createTree(withChildren: [gainParameter, bypassParameter])
        
        // Set up parameter observers
        parameterTree?.implementorValueObserver = { [weak self] parameter, value in
            guard let self = self else { return }
            
            switch parameter.address {
            case 0: // Gain
                self.gain = value
                self.log.debug("Gain parameter changed: \(value)")
            case 1: // Bypass
                self.bypass = value >= 0.5
                self.log.debug("Bypass parameter changed: \(self.bypass)")
            default:
                break
            }
        }
        
        parameterTree?.implementorValueProvider = { [weak self] parameter in
            guard let self = self else { return 0 }
            
            switch parameter.address {
            case 0: // Gain
                return self.gain
            case 1: // Bypass
                return self.bypass ? 1.0 : 0.0
            default:
                return 0
            }
        }
    }
    
    // MARK: - AUAudioUnit Overrides
    
    public override var inputBusses: AUAudioUnitBusArray {
        return inputBusArray
    }
    
    public override var outputBusses: AUAudioUnitBusArray {
        return outputBusArray
    }
    
    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()
        log.info("Render resources allocated")
    }
    
    public override func deallocateRenderResources() {
        super.deallocateRenderResources()
        log.info("Render resources deallocated")
    }
    
    public override var internalRenderBlock: AUInternalRenderBlock {
        return { [weak self] (
            actionFlags,
            timestamp,
            frameCount,
            outputBusNumber,
            outputData,
            realtimeEventListHead,
            pullInputBlock
        ) in
            guard let self = self else { return kAudioUnitErr_NoConnection }
            
            // Pull input
            var pullFlags = AudioUnitRenderActionFlags(rawValue: 0)
            let status = pullInputBlock?(&pullFlags, timestamp, frameCount, 0, outputData)
            
            if status != noErr {
                return status ?? kAudioUnitErr_NoConnection
            }
            
            // If bypassed, just return the input as-is
            if self.bypass {
                return noErr
            }
            
            // Apply gain to each channel
            let channelCount = Int(outputData.pointee.mNumberBuffers)
            let buffers = UnsafeMutableAudioBufferListPointer(outputData)
            
            for bufferIndex in 0..<channelCount {
                guard let buffer = buffers[bufferIndex].mData else { continue }
                let floatBuffer = buffer.assumingMemoryBound(to: Float.self)
                
                for frame in 0..<Int(frameCount) {
                    floatBuffer[frame] *= self.gain
                }
            }
            
            return noErr
        }
    }
    
    // MARK: - View Controller
    
    public override func requestViewController(completionHandler: @escaping (AUViewController?) -> Void) {
        DispatchQueue.main.async {
            let viewController = EffectViewController(audioUnit: self)
            completionHandler(viewController)
        }
    }
}
