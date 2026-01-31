import AVFoundation
import AudioToolbox
import CoreAudioKit
import os

#if os(iOS)
import UIKit
#endif

/// 简单音频引擎
@MainActor
@Observable
public class AudioEngine {
    
    private let log = Logger(subsystem: "com.test.AUv3TestHost", category: "AudioEngine")
    
    // AVAudioEngine
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    
    // 当前加载的插件
    public var currentAudioUnit: AVAudioUnit?
    public var currentViewController: AUViewController?
    
    // 状态
    public var isPlaying = false
    public var isLoading = false
    
    // 测试音频文件
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
            
            // Set preferred buffer duration for low latency
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms for low latency
            
        } catch {
            log.error("Failed to configure iOS audio session: \(error.localizedDescription)")
        }
    }
    #endif
    
    private func setupEngine() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        engine.prepare()
        
        // 加载测试音频（可选）
        if let url = Bundle.main.url(forResource: "TestAudio", withExtension: "wav") {
            testFile = try? AVAudioFile(forReading: url)
        }
    }
    
    // MARK: - 加载插件
    
    /// 加载 AUv3 插件并测量性能
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
        
        // 1. 卸载当前插件
        await unloadCurrentPlugin()
        
        #if os(iOS)
        // Ensure audio session is active before loading plugin
        ensureIOSAudioSessionActive()
        #endif
        
        // 2. 实例化 AudioUnit
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
            
            // 3. 连接音频图
            let connectStart = CFAbsoluteTimeGetCurrent()
            connectPlugin(audioUnit)
            let connectEnd = CFAbsoluteTimeGetCurrent()
            metrics.connectAudioGraphTime = (connectEnd - connectStart) * 1000
            
            // 4. 分配渲染资源
            let allocateStart = CFAbsoluteTimeGetCurrent()
            try engine.start()
            let allocateEnd = CFAbsoluteTimeGetCurrent()
            metrics.allocateResourcesTime = (allocateEnd - allocateStart) * 1000
            
            // 5. 加载 ViewController
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
        
        // 记录指标
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
        // 断开现有连接
        engine.disconnectNodeInput(engine.mainMixerNode)
        
        // 连接插件
        engine.attach(audioUnit)
        
        let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
        
        if audioUnit.auAudioUnit.componentDescription.componentType == kAudioUnitType_Effect ||
           audioUnit.auAudioUnit.componentDescription.componentType == kAudioUnitType_MusicEffect {
            // 效果器: player -> effect -> mixer
            let format = testFile?.processingFormat ?? hardwareFormat
            engine.connect(player, to: audioUnit, format: format)
            engine.connect(audioUnit, to: engine.mainMixerNode, format: format)
        } else {
            // 乐器/生成器: instrument -> mixer
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
        
        // 重新连接 player -> mixer
        engine.connect(player, to: engine.mainMixerNode, format: nil)
    }
    
    // MARK: - 播放控制
    
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