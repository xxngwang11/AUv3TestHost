# Building AUv3TestHost for iOS

## ⚠️ Important Update

This project now includes comprehensive Xcode project setup instructions. Please see [XCODE_PROJECT_SETUP.md](XCODE_PROJECT_SETUP.md) for:
- Complete Xcode project creation guide
- Required build settings and entitlements
- Code signing configuration
- Command-line build instructions
- Troubleshooting tips

## Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later
- An iOS device running iOS 17.0+ (for testing on real hardware)
- Apple Developer account (for device deployment)

## Recent Improvements

The following improvements have been made for better iOS support:

1. **Package.swift** - Changed from executable to library target for iOS compatibility
2. **Adaptive UI** - iPhone and iPad optimized layouts (NavigationStack on iPhone, NavigationSplitView on iPad)
3. **Enhanced Audio Session** - Complete interruption and route change handling
4. **Better Error Handling** - Comprehensive diagnostics and error reporting
5. **Entitlements** - Proper iOS entitlements for audio unit hosting
6. **Diagnostics View** - Built-in troubleshooting tool accessible from the app

## Building for iOS

This project is a SwiftUI-based iOS/macOS application. While the repository uses Swift Package Manager structure, **iOS apps should be built using Xcode** rather than SPM command-line tools.

### Option 1: Build with Xcode (Recommended)

1. Open the project in Xcode:
   ```bash
   cd /path/to/AUv3TestHost
   open Package.swift
   ```

2. In Xcode:
   - Select your target device or simulator from the device menu
   - Choose Product → Build (⌘B)
   - Choose Product → Run (⌘R) to run the app

### Option 2: Build with xcodebuild

```bash
# For iOS Simulator
xcodebuild -scheme AUv3TestHost -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# For iOS Device (requires code signing)
xcodebuild -scheme AUv3TestHost -destination 'platform=iOS,id=<DEVICE_UDID>' build
```

## iOS-Specific Features

The following iOS-specific features have been implemented:

### 1. Audio Session Configuration (`AUv3TestHostApp.swift` and `AudioEngine.swift`)
- Automatic AVAudioSession setup on app launch and during plugin loading
- Background audio support
- Audio interruption handling (phone calls, alarms, etc.) with automatic recovery
- Audio route change monitoring (headphones, Bluetooth) with playback control
- Enhanced error logging for iOS-specific audio issues

### 2. Permissions (`Info.plist`)
- Microphone access permission with description
- Background audio mode enabled
- iPhone and iPad orientation support

### 3. Audio Engine Enhancements (`AudioEngine.swift`)
- iOS-specific audio session initialization in both AppDelegate and AudioEngine
- Enhanced error handling for iOS audio issues with detailed OSStatus codes
- Low-latency buffer configuration
- Platform-specific error logging
- Interruption and route change observers for robust audio handling

### 4. ViewController Handling (`AUViewControllerRepresentable.swift`)
- Proper iOS view controller presentation
- Auto-layout configuration
- Cleanup on dismissal

### 5. Adaptive UI (`ContentView.swift`)
- NavigationStack layout for iPhone (compact size class)
- NavigationSplitView layout for iPad and macOS (regular size class)
- Environment-based responsive design

### 6. Enhanced Plugin Scanner (`AudioUnitLoader.swift`)
- Comprehensive error handling and diagnostics
- iOS-specific permission and sandbox checks
- Detailed logging of scan results
- Platform-aware error messages

### 7. Diagnostics View
- Real-time system information display
- Audio session status monitoring
- Plugin scanner diagnostics
- Troubleshooting recommendations
- Accessible via info button in toolbar

## Testing on iOS

### Testing Audio Session
1. Launch the app
2. Check the console logs for "Audio session configured successfully"
3. Verify sample rate and buffer duration are logged

### Testing AUv3 Plugin Loading
1. Ensure you have AUv3 plugins installed on your iOS device
2. Select a plugin type from the segmented control
3. Choose a plugin from the list
4. Tap "Load" to load the plugin
5. The plugin's UI should appear if it has one
6. Check for any error messages in the console

### Testing Audio Playback
1. Load a plugin (effect or instrument)
2. Tap "Play" to start audio playback
3. Verify audio plays through the device speakers/headphones
4. Test with headphones plugged/unplugged
5. Test with Bluetooth audio devices

### Common Issues

#### "No audio session configured"
- Make sure the app has microphone permissions
- Check Settings → Privacy → Microphone → AUv3TestHost

#### "Audio Unit error"
- Ensure the plugin is compatible with iOS 17.0+
- Try loading the plugin in-process vs out-of-process
- Check that the audio session is active

#### Plugin UI not appearing
- Some plugins don't provide a UI
- Check console logs for ViewController loading errors
- Verify the plugin is properly instantiated

## Building on Linux (Not Supported)

This is an iOS/macOS application that requires Apple platform frameworks (SwiftUI, AVFoundation, CoreAudioKit). It cannot be built on Linux. The Package.swift file is provided for project structure and dependency management on macOS.
