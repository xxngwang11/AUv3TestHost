import SwiftUI
#if os(iOS)
import AVFoundation
import UIKit
import os
#endif

#if os(iOS)
// AppDelegate for iOS-specific audio session configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    private let log = Logger(subsystem: "com.test.AUv3TestHost", category: "AppDelegate")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        setupAudioSession()
        return true
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Configure audio session for playback and recording
            // This is essential for AUv3 plugin hosting on iOS
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            
            // Activate the audio session
            try audioSession.setActive(true)
            
            log.info("Audio session configured successfully")
            log.info("Sample Rate: \(audioSession.sampleRate) Hz")
            log.info("IO Buffer Duration: \(audioSession.ioBufferDuration * 1000) ms")
            log.info("Output Channels: \(audioSession.outputNumberOfChannels)")
            log.info("Input Channels: \(audioSession.inputNumberOfChannels)")
            
        } catch {
            log.error("Failed to configure audio session: \(error.localizedDescription)")
        }
        
        // Monitor audio session interruptions
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioSessionInterruption(notification)
        }
        
        // Monitor route changes (headphone plug/unplug, etc.)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioRouteChange(notification)
        }
    }
    
    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            log.info("Audio session interrupted")
        case .ended:
            log.info("Audio session interruption ended")
            // Optionally reactivate the session
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        log.info("Audio session reactivated after interruption")
                    } catch {
                        log.error("Failed to reactivate audio session: \(error.localizedDescription)")
                    }
                }
            }
        @unknown default:
            break
        }
    }
    
    private func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .newDeviceAvailable:
            log.info("New audio device available")
        case .oldDeviceUnavailable:
            log.info("Audio device removed")
        case .categoryChange:
            log.info("Audio session category changed")
        case .override:
            log.info("Audio route override")
        case .wakeFromSleep:
            log.info("Audio route change: wake from sleep")
        case .noSuitableRouteForCategory:
            log.warning("No suitable route for audio category")
        case .routeConfigurationChange:
            log.info("Audio route configuration changed")
        @unknown default:
            log.info("Unknown audio route change reason")
        }
    }
}
#endif

@main
struct AUv3TestHostApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}