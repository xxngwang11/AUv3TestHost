# AUv3 Test Host

A simple macOS/iOS host application for testing and benchmarking AUv3 (Audio Unit v3) plugin load performance.

## Features

- 🔍 **Plugin Discovery**: Scan and list all installed AUv3 plugins by type (Effect, Instrument, MIDI Processor, etc.)
- ⏱️ **Performance Metrics**: Measure detailed load times for each stage:
  - Component instantiation
  - Audio graph connection
  - Resource allocation
  - ViewController loading
- 📊 **Benchmark Mode**: Run multiple load tests and calculate average performance
- 🔄 **Load Options**: Compare Out-of-Process vs In-Process loading (defaults to out-of-process)
- 📈 **History Tracking**: View historical load performance data
- 🎵 **iOS Support**: Full iOS compatibility with proper audio session management
- 🎛️ **Test Plugin Included**: Simple Effect plugin for testing audio chain and UI integration

## Requirements

- macOS 14.0+ / iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Building

### For macOS
Build using Xcode by opening Package.swift, or use xcodebuild on macOS.

### For iOS
iOS apps require Xcode for building. See [XCODE_PROJECT_SETUP.md](XCODE_PROJECT_SETUP.md) for detailed iOS build and project setup instructions.

**Important for iOS:**
- The Package.swift uses a library target (not executable) for iOS compatibility
- You must use Xcode to build and run iOS apps
- Proper code signing and entitlements are required
- See the setup guide for complete instructions

**Note**: This project cannot be built on Linux as it requires Apple platform frameworks (SwiftUI, AVFoundation, CoreAudioKit).

## iOS-Specific Features

- ✅ Automatic AVAudioSession configuration
- ✅ Microphone permission handling
- ✅ Background audio support
- ✅ Audio interruption handling (phone calls, etc.)
- ✅ Audio route change monitoring (headphones, Bluetooth)
- ✅ Enhanced error handling for iOS audio issues
- ✅ Adaptive UI for iPhone and iPad
- ✅ Comprehensive diagnostics view for troubleshooting
- ✅ Proper entitlements for audio unit hosting

## Test Plugin

The repository includes a simple AUv3 Effect plugin (TestEffectAUv3) for testing:
- **Gain Control**: Adjust audio volume from 0.0 to 2.0
- **Bypass Switch**: Enable/disable effect processing
- **SwiftUI Interface**: Real-time parameter display
- **Out-of-Process**: Tests plugin isolation and stability

See [PLUGIN_TESTING.md](PLUGIN_TESTING.md) for setup and testing instructions.

## Usage

### Host Application

1. Select a plugin type from the segmented control
2. Choose a plugin from the list
3. Out-of-Process option is enabled by default (recommended)
4. Click/Tap "Load" to load the plugin and measure performance
5. Click/Tap "Benchmark x5" to run multiple load tests

### Test Plugin

1. Build and run **TestPluginContainer** on your iOS device
2. Build and run **AUv3TestHost** on the same device
3. Tap "Refresh Plugins" and select "Effect" type
4. Find "TestCompany: Test Effect" in the list
5. Load the plugin and test the audio chain

**Note**: The test plugin requires manual Xcode project configuration. See PLUGIN_TESTING.md for details.

## Performance Guidelines

| Load Time | Rating |
|-----------|--------|
| < 200ms | 🟢 Excellent |
| 200-500ms | 🟡 Good |
| > 500ms | 🔴 Needs Optimization |

## License

MIT License
