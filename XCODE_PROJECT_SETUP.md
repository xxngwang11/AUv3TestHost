# Xcode Project Configuration Guide

This guide explains how to create an Xcode project for AUv3TestHost to enable iOS builds.

## Quick Setup

### Option 1: Using Xcode (Recommended)

1. Open Package.swift in Xcode:
   ```bash
   open Package.swift
   ```

2. Xcode will automatically create a workspace for the Swift package

3. Select the appropriate target (iOS or macOS) and device

4. Build and run with ⌘R

### Option 2: Create Xcode Project from Scratch

1. Create a new iOS/macOS app project in Xcode
2. Set the following:
   - Product Name: AUv3TestHost
   - Bundle Identifier: com.test.AUv3TestHost
   - Interface: SwiftUI
   - Language: Swift
   - Platform: iOS 17.0+ / macOS 14.0+

3. Copy all Swift files from `AUv3TestHost/` directory to the project

4. Add the entitlements file:
   - Add `AUv3TestHost.entitlements` to the project
   - In Build Settings, set Code Signing Entitlements to `AUv3TestHost/AUv3TestHost.entitlements`

5. Configure Info.plist:
   - Copy settings from `AUv3TestHost/Info.plist`
   - Ensure microphone usage description is present
   - Enable background audio mode

## Required Xcode Project Settings

### Build Settings

```
PRODUCT_NAME = AUv3TestHost
PRODUCT_BUNDLE_IDENTIFIER = com.test.AUv3TestHost
MARKETING_VERSION = 1.0
CURRENT_PROJECT_VERSION = 1

IPHONEOS_DEPLOYMENT_TARGET = 17.0
MACOSX_DEPLOYMENT_TARGET = 14.0

SWIFT_VERSION = 5.9
ENABLE_PREVIEWS = YES

CODE_SIGN_ENTITLEMENTS = AUv3TestHost/AUv3TestHost.entitlements
CODE_SIGN_STYLE = Automatic
DEVELOPMENT_TEAM = <Your Team ID>
```

### Info.plist Keys (iOS)

Required keys for iOS functionality:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to the microphone to process audio through AUv3 plugins.</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>

<key>UIApplicationSupportsIndirectInputEvents</key>
<true/>

<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
</dict>
```

### Entitlements (iOS)

The `AUv3TestHost.entitlements` file includes:

- Audio Unit Host capability
- Device audio input
- Microphone access
- Inter-app audio

## Code Signing

### For Development

1. In Xcode, select the project
2. Go to "Signing & Capabilities"
3. Select your development team
4. Xcode will automatically manage provisioning profiles

### For Distribution

1. Create an App ID in Apple Developer portal
2. Create a provisioning profile
3. Download and install the profile
4. Select the profile in Xcode build settings

## Building from Command Line

### Using xcodebuild

Once the project is set up in Xcode:

```bash
# Build for iOS Simulator
xcodebuild -scheme AUv3TestHost \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    build

# Build for iOS Device
xcodebuild -scheme AUv3TestHost \
    -destination 'platform=iOS,id=<DEVICE_UDID>' \
    -allowProvisioningUpdates \
    build

# Build for macOS
xcodebuild -scheme AUv3TestHost \
    -destination 'platform=macOS' \
    build
```

### Using Swift Package Manager (Limited)

SPM can build the code but cannot create iOS app bundles:

```bash
# This will build the library but not create a runnable iOS app
swift build
```

For actual iOS apps, you must use Xcode or xcodebuild.

## Testing

### On iOS Simulator

1. Select an iPhone or iPad simulator
2. Build and run with ⌘R
3. Note: Some audio features may be limited on simulator

### On iOS Device

1. Connect your iOS device
2. Trust the device in Xcode
3. Select the device from the device menu
4. Build and run with ⌘R
5. First run may require trusting the developer certificate on device

## Troubleshooting

### "No provisioning profiles found"

- Ensure you're signed in to Xcode with your Apple ID
- Check that automatic signing is enabled
- Verify your Apple Developer account has the necessary permissions

### "AUv3 plugins not found"

- Install AUv3 plugins from the App Store on your device
- Ensure the app has microphone permissions
- Check that audio session is properly configured (see logs)

### "Audio session configuration failed"

- Grant microphone permission in Settings → Privacy
- Ensure Info.plist includes NSMicrophoneUsageDescription
- Check that entitlements file is properly linked

### "Build failed with signing errors"

- Select your development team in build settings
- Ensure bundle identifier is unique
- Check that entitlements are compatible with your team

## Directory Structure

```
AUv3TestHost/
├── Package.swift                    # Swift Package definition
├── AUv3TestHost/
│   ├── AUv3TestHostApp.swift       # App entry point
│   ├── ContentView.swift            # Main UI
│   ├── Info.plist                   # iOS app configuration
│   ├── AUv3TestHost.entitlements   # Capabilities and permissions
│   ├── Audio/
│   │   └── AudioEngine.swift        # Audio processing
│   ├── Models/
│   │   ├── AudioUnitLoader.swift    # Plugin scanner
│   │   └── LoadMetrics.swift        # Performance metrics
│   └── Views/
│       ├── PluginDetailView.swift   # Plugin details
│       ├── PluginRow.swift          # Plugin list item
│       ├── MetricBar.swift          # Performance visualization
│       ├── MetricsHistoryView.swift # History view
│       ├── DiagnosticsView.swift    # Diagnostics and troubleshooting
│       └── AUViewControllerRepresentable.swift  # UI integration
├── BUILD_INSTRUCTIONS.md            # iOS build guide
└── XCODE_PROJECT_SETUP.md           # Xcode project setup (this file)
```

## Additional Resources

- [Apple Audio Unit v3 Programming Guide](https://developer.apple.com/library/archive/documentation/AudioUnit/Conceptual/AudioUnitProgrammingGuide/)
- [AVAudioEngine Documentation](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
