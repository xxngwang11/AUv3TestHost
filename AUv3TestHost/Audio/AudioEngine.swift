import AVFoundation
import AudioToolbox
import CoreAudioKit
import os

#if os(iOS)
import UIKit
#endif

/// Simple Audio Engine for AUv3 plugin hosting and performance measurement
@MainActor
@Observable
public class AudioEngine {
    
    private let log = Logger(subsystem: "com.test.AUv3TestHost", category: "AudioEngine")
    
    // AVAudioEngine
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    
    // Currently loaded plugin
    public var currentAudioUnit: AVAudioUnit?
    public var currentViewController: AUViewController?
    
    // State
    public var isPlaying = false
    public var isLoading = false
    
    // Test audio file
    private var testFile: AVAudioFile?
    
    public init() {
        setupEngine()
        #if os(iOS)
        setupIOSAudioSession()
        #endif
    }
    
    #if os(iOS)
    private func setupIOSAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Ensure audio session is properly configured
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            
            log.info("iOS audio session configured in AudioEngine")
            log.info("Preferred sample rate: \(audioSession.preferredSampleRate) Hz")
            log.info("Preferred buffer duration: \(audioSession.preferredIOBufferDuration * 1000) ms")
            
            // Set preferred buffer duration for low latency (5 milliseconds = 0.005 seconds)
            let lowLatencyBufferDuration: TimeInterval = 0.005
            try audioSession.setPreferredIOBufferDuration(lowLatencyBufferDuration)
            
        } catch {
            log.error("Failed to configure iOS audio session: \(error.localizedDescription)")
        }
    }
    #endif
    
    private func setupEngine() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        engine.prepare()
        
        // Load test audio (optional)
        if let url = Bundle.main.url(forResource: "TestAudio", withExtension: "wav") {
            testFile = try? AVAudioFile(forReading: url)
        }
    }
    
    // MARK: - Plugin Loading
    
    /// Load AUv3 plugin and measure performance
    public func loadPlugin(
        component: AVAudioUnitComponent,
        outOfProcess: Bool = true
    ) async -> PluginLoadMetrics {
        
        isLoading = true
        defer { isLoading = false }
        
        var metrics = PluginLoadMetrics(
            pluginName: component.name,
            timestamp: Date(),
            loadedOutOfProcess: outOfProcess
        )
        
        let totalStart = CFAbsoluteTimeGetCurrent()
        
        // 1. Unload current plugin
        await unloadCurrentPlugin()
        
        #if os(iOS)
        // Ensure audio session is active before loading plugin
        ensureIOSAudioSessionActive()
        #endif
        
        // 2. Instantiate AudioUnit
        let instantiateStart = CFAbsoluteTimeGetCurrent()
        
        let options: AudioComponentInstantiationOptions = outOfProcess ? .loadOutOfProcess : .loadInProcess
        
        do {
            let audioUnit = try await AVAudioUnit.instantiate(
                with: component.audioComponentDescription,
                options: options
            )
            
            let instantiateEnd = CFAbsoluteTimeGetCurrent()
            metrics.instantiateTime = (instantiateEnd - instantiateStart) * 1000
            
            self.currentAudioUnit = audioUnit
            
            // 3. Connect audio graph
            let connectStart = CFAbsoluteTimeGetCurrent()
            connectPlugin(audioUnit)
            let connectEnd = CFAbsoluteTimeGetCurrent()
            metrics.connectAudioGraphTime = (connectEnd - connectStart) * 1000
            
            // 4. Allocate render resources
            let allocateStart = CFAbsoluteTimeGetCurrent()
            try engine.start()
            let allocateEnd = CFAbsoluteTimeGetCurrent()
            metrics.allocateResourcesTime = (allocateEnd - allocateStart) * 1000
            
            // 5. Load ViewController
            let loadVCStart = CFAbsoluteTimeGetCurrent()
            if let vc = await audioUnit.auAudioUnit.requestViewController(completionHandler: { _ in }) {
                self.currentViewController = vc as? AUViewController
            }
            let loadVCEnd = CFAbsoluteTimeGetCurrent()
            metrics.loadViewControllerTime = (loadVCEnd - loadVCStart) * 1000
            
        } catch let error as NSError {
            #if os(iOS)
            // iOS-specific error handling
            if error.domain == NSOSStatusErrorDomain {
                log.error("Audio Unit error (OSStatus \(error.code)): \(error.localizedDescription)")
                if error.code == Int(kAudioUnitErr_InvalidProperty) {
                    log.error("Invalid property - check audio session configuration")
                } else if error.code == Int(kAudioUnitErr_FormatNotSupported) {
                    log.error("Format not supported - check audio format compatibility")
                }
            } else {
                log.error("Failed to load plugin: \(error.localizedDescription)")
            }
            #else
            log.error("Failed to load plugin: \(error.localizedDescription)")
            #endif
        }
        
        let totalEnd = CFAbsoluteTimeGetCurrent()
        metrics.totalTime = (totalEnd - totalStart) * 1000
        
        // Record metrics
        await MetricsManager.shared.record(metrics)
        
        return metrics
    }
    
    #if os(iOS)
    private func ensureIOSAudioSessionActive() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(true)
            log.info("iOS audio session activated for plugin loading")
        } catch {
            log.error("Failed to activate iOS audio session: \(error.localizedDescription)")
        }
    }
    #endif
    
    private func connectPlugin(_ audioUnit: AVAudioUnit) {
        // Disconnect existing connections
        engine.disconnectNodeInput(engine.mainMixerNode)
        
        // Connect plugin
        engine.attach(audioUnit)
        
        let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
        
        if audioUnit.auAudioUnit.componentDescription.componentType == kAudioUnitType_Effect ||
           audioUnit.auAudioUnit.componentDescription.componentType == kAudioUnitType_MusicEffect {
            // Effect: player -> effect -> mixer
            let format = testFile?.processingFormat ?? hardwareFormat
            engine.connect(player, to: audioUnit, format: format)
            engine.connect(audioUnit, to: engine.mainMixerNode, format: format)
        } else {
            // Instrument/Generator: instrument -> mixer
            let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareFormat.sampleRate, channels: 2)
            engine.connect(audioUnit, to: engine.mainMixerNode, format: stereoFormat)
        }
        
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)
    }
    
    public func unloadCurrentPlugin() async {
        stopPlaying()
        engine.stop()
        
        if let audioUnit = currentAudioUnit {
            engine.disconnectNodeInput(engine.mainMixerNode)
            engine.detach(audioUnit)
        }
        
        currentAudioUnit = nil
        currentViewController = nil
        
        // Reconnect player -> mixer
        engine.connect(player, to: engine.mainMixerNode, format: nil)
    }
    
    // MARK: - Playback Control
    
    public func startPlaying() {
        guard !isPlaying else { return }
        
        do {
            #if os(iOS)
            // Ensure audio session is active before starting playback
            ensureIOSAudioSessionActive()
            #endif
            
            if !engine.isRunning {
                try engine.start()
            }
            
            if let file = testFile {
                player.scheduleFile(file, at: nil) { [weak self] in
                    DispatchQueue.main.async {
                        self?.isPlaying = false
                    }
                }
            }
            
            player.play()
            isPlaying = true
            
            log.info("Audio playback started successfully")
            
        } catch let error as NSError {
            #if os(iOS)
            if error.domain == NSOSStatusErrorDomain {
                log.error("Audio playback error (OSStatus \(error.code)): \(error.localizedDescription)")
            } else if error.domain == AVAudioSessionErrorDomain {
                log.error("Audio session error: \(error.localizedDescription)")
            } else {
                log.error("Failed to start playing: \(error.localizedDescription)")
            }
            #else
            log.error("Failed to start playing: \(error.localizedDescription)")
            #endif
        }
    }
    
    public func stopPlaying() {
        player.stop()
        isPlaying = false
        log.info("Audio playback stopped")
    }
}