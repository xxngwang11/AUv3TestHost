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
            
            // Add audio session interruption observer
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioSessionInterruption(_:)),
                name: AVAudioSession.interruptionNotification,
                object: audioSession
            )
            
            // Add audio route change observer
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioRouteChange(_:)),
                name: AVAudioSession.routeChangeNotification,
                object: audioSession
            )
            
            log.info("Audio session observers registered")
            
        } catch {
            log.error("Failed to configure iOS audio session: \(error.localizedDescription)")
        }
    }
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            log.info("AudioEngine: Audio session interrupted - stopping playback")
            stopPlaying()
            
        case .ended:
            log.info("AudioEngine: Audio session interruption ended")
            // Check if we should resume
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    log.info("AudioEngine: Resuming audio session")
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        // Optionally restart engine if needed
                        if currentAudioUnit != nil && !engine.isRunning {
                            try engine.start()
                        }
                    } catch {
                        log.error("AudioEngine: Failed to reactivate audio session: \(error.localizedDescription)")
                    }
                }
            }
            
        @unknown default:
            log.warning("AudioEngine: Unknown interruption type")
        }
    }
    
    @objc private func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .newDeviceAvailable:
            log.info("AudioEngine: New audio device available")
            
        case .oldDeviceUnavailable:
            log.info("AudioEngine: Audio device removed - may need to stop playback")
            // Optionally stop playback when headphones are unplugged
            if isPlaying {
                stopPlaying()
            }
            
        case .categoryChange:
            log.info("AudioEngine: Audio session category changed")
            
        case .override:
            log.info("AudioEngine: Audio route override")
            
        case .wakeFromSleep:
            log.info("AudioEngine: Audio route change - wake from sleep")
            
        case .noSuitableRouteForCategory:
            log.warning("AudioEngine: No suitable route for audio category")
            
        case .routeConfigurationChange:
            log.info("AudioEngine: Audio route configuration changed")
            
        @unknown default:
            log.info("AudioEngine: Unknown audio route change reason")
        }
    }
    #endif
    
    private func setupEngine() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        engine.prepare()
        
        // Load test audio from Resources
        if let url = Bundle.main.url(forResource: "TestAudio", withExtension: "wav") {
            do {
                testFile = try AVAudioFile(forReading: url)
                log.info("Successfully loaded TestAudio.wav from bundle")
                log.info("Audio format: \(testFile!.processingFormat.sampleRate) Hz, \(testFile!.processingFormat.channelCount) channels")
            } catch {
                log.error("Failed to load TestAudio.wav: \(error.localizedDescription)")
                generateFallbackAudio()
            }
        } else {
            log.warning("TestAudio.wav not found in bundle, generating fallback audio")
            generateFallbackAudio()
        }
    }
    
    private func generateFallbackAudio() {
        // Generate a simple sine wave as fallback
        let sampleRate = 44100.0
        let duration = 2.0 // 2 seconds
        let frequency = 440.0 // A4 note
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            log.error("Failed to create audio buffer for fallback")
            return
        }
        
        buffer.frameLength = frameCount
        
        // Generate sine wave
        let channelCount = Int(format.channelCount)
        for channel in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            for frame in 0..<Int(frameCount) {
                let time = Double(frame) / sampleRate
                let sample = Float(sin(2.0 * .pi * frequency * time) * 0.3)
                channelData[frame] = sample
            }
        }
        
        // Create temporary file for the buffer
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent("FallbackAudio.wav")
        
        do {
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false
            ]
            
            let file = try AVAudioFile(forWriting: tempURL, settings: settings)
            try file.write(from: buffer)
            
            testFile = try AVAudioFile(forReading: tempURL)
            log.info("Generated fallback sine wave audio (440 Hz, 2s)")
        } catch {
            log.error("Failed to generate fallback audio: \(error.localizedDescription)")
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
        
        let options: AudioComponentInstantiationOptions = .loadOutOfProcess
        
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
            let vc = await withCheckedContinuation { continuation in
                    audioUnit.auAudioUnit.requestViewController { viewController in
                        continuation.resume(returning: viewController as? AUViewController)
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
                // Schedule the file to loop
                scheduleAudioLoop(file: file)
            } else {
                log.warning("No test audio file available for playback")
            }
            
            player.play()
            isPlaying = true
            
            log.info("Audio playback started successfully")
            
        } catch let error as NSError {
            #if os(iOS)
            if error.domain == NSOSStatusErrorDomain {
                log.error("Audio playback error (OSStatus \(error.code)): \(error.localizedDescription)")
            } else {
                log.error("Failed to start playing: \(error.localizedDescription)")
            }
            #else
            log.error("Failed to start playing: \(error.localizedDescription)")
            #endif
        }
    }
    
    private func scheduleAudioLoop(file: AVAudioFile) {
        // Schedule file and set up completion handler to loop
        player.scheduleFile(file, at: nil) { [weak self] in
            guard let self = self else { return }
            
            // If still playing, schedule the file again for looping
            DispatchQueue.main.async {
                if self.isPlaying {
                    self.scheduleAudioLoop(file: file)
                }
            }
        }
    }
    
    public func stopPlaying() {
        player.stop()
        isPlaying = false
        log.info("Audio playback stopped")
    }
}
