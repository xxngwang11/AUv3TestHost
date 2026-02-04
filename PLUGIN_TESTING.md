# AUv3 Test Effect Plugin Testing Guide

This document explains how to test the Test Effect AUv3 plugin in the AUv3TestHost application.

## Overview

The repository now includes a simple AUv3 Effect plugin for testing the host application. The plugin consists of:

1. **TestPluginContainer** - iOS app that hosts the Audio Unit extension
2. **TestEffectAUv3** - Audio Unit v3 extension with UI (gain control + bypass switch)

## Plugin Features

The Test Effect plugin provides:
- **Gain Control**: Slider to adjust audio volume (0.0 to 2.0)
- **Bypass Switch**: Enable/disable the effect processing
- **Real-time UI**: SwiftUI interface showing current parameter values

## Testing Instructions

### Prerequisites
- macOS with Xcode 15.0 or later
- iOS device running iOS 17.0+ (simulator may have limited audio functionality)
- Apple Developer account for code signing

### Step 1: Configure Xcode Project

The source code for the plugin has been created in:
- `TestPluginContainer/` - Container app files
- `TestEffectAUv3/` - Extension files (AudioUnit implementation, UI, factory function)

**To complete the setup, you need to add these targets to the Xcode project:**

1. Open `AUv3TestHost.xcodeproj` in Xcode
2. Add a new iOS App target named "TestPluginContainer":
   - Bundle Identifier: `com.test.TestPluginContainer`
   - Add files from `TestPluginContainer/` folder
   - Set deployment target to iOS 17.0
   
3. Add a new App Extension target named "TestEffectAUv3":
   - Extension Type: Audio Unit v3
   - Bundle Identifier: `com.test.TestPluginContainer.TestEffectAUv3`
   - Add files from `TestEffectAUv3/` folder
   - Embed in TestPluginContainer
   - Set deployment target to iOS 17.0

4. Configure the extension's Info.plist with AudioComponents:
   ```xml
   <key>AudioComponents</key>
   <array>
       <dict>
           <key>name</key>
           <string>TestCompany: Test Effect</string>
           <key>description</key>
           <string>Simple gain effect for testing AUv3 hosting</string>
           <key>factoryFunction</key>
           <string>TestEffectAudioUnitFactory</string>
           <key>manufacturer</key>
           <string>Test</string>
           <key>type</key>
           <string>aufx</string>
           <key>subtype</key>
           <string>teff</string>
           <key>version</key>
           <integer>1</integer>
           <key>sandboxSafe</key>
           <true/>
           <key>tags</key>
           <array>
               <string>Effects</string>
           </array>
       </dict>
   </array>
   ```

### Step 2: Install the Plugin Container

1. Select the **TestPluginContainer** scheme in Xcode
2. Choose your iOS device as the destination
3. Build and run (⌘R)
4. The app will install and register the TestEffectAUv3 extension with the system
5. You can close the container app after it launches

### Step 3: Run the Host Application

1. Select the **AUv3TestHost** scheme in Xcode
2. Build and run on the same iOS device
3. The host app will launch with the plugin scanner

### Step 4: Load and Test the Plugin

1. In AUv3TestHost, tap "Refresh Plugins" to scan for available plugins
2. Ensure "Effect" is selected in the type picker
3. Look for "TestCompany: Test Effect" in the plugin list
4. Tap the plugin to select it
5. The plugin detail view will appear
6. Tap "Load" to instantiate the plugin
7. The plugin's UI should appear showing:
   - Bypass toggle switch
   - Gain slider (0.0 to 2.0)
   - Current parameter values display

### Step 5: Test Audio Processing

1. With the plugin loaded and UI visible, tap "Play Test Audio"
2. You should hear the test audio playing through the plugin
3. Adjust the Gain slider:
   - Move towards 0.0: audio gets quieter
   - Move towards 2.0: audio gets louder
4. Toggle the Bypass switch:
   - ON: audio bypasses the effect (original volume)
   - OFF: gain effect is applied
5. The status text updates to show current parameter values

### Step 6: Test Out-of-Process Loading

The host application defaults to loading plugins out-of-process. This is the recommended mode for:
- Better stability (plugin crashes don't crash the host)
- Security sandboxing
- Resource isolation

You can verify this by checking the "Out-of-Process" toggle is enabled before loading.

## Troubleshooting

### Plugin Not Found
- Ensure TestPluginContainer was run at least once on the device
- Try rebooting the device to refresh the Audio Component cache
- Check Console.app for any extension loading errors

### No Audio Output
- Verify microphone permissions are granted to AUv3TestHost
- Check audio session configuration in console logs
- Try with headphones connected

### Plugin UI Not Appearing
- Check that the plugin loaded successfully (no error messages)
- Verify the extension's Info.plist is correctly configured
- Look for ViewController loading errors in console

### Build Errors
- Ensure all files are properly added to their respective targets
- Verify bundle identifiers are correctly configured
- Check code signing settings match for all targets

## Implementation Details

### Audio Processing
The plugin implements a simple gain effect:
- Input audio is multiplied by the gain value (0.0 to 2.0)
- When bypassed, audio passes through unmodified
- Processing happens in the `internalRenderBlock` callback

### Parameter Management
- Uses `AUParameterTree` for parameter handling
- Gain parameter (address 0): 0.0 to 2.0, default 1.0
- Bypass parameter (address 1): 0 or 1, default 0
- Parameters are observable and can be automated

### UI Implementation
- SwiftUI-based interface for modern iOS design
- Real-time parameter updates via timer-based polling
- Bidirectional parameter binding (UI ↔ AudioUnit)

## Next Steps

After successful testing, you can:
1. Modify the plugin's DSP code to implement different effects
2. Add more parameters (e.g., filters, delays, reverb)
3. Enhance the UI with visualizations or preset management
4. Test with different audio sources and plugin types

## Code Structure

```
TestPluginContainer/
  ├── ContainerApp.swift          # App entry point
  ├── ContentView.swift            # Installation instructions UI
  └── Info.plist                   # App configuration

TestEffectAUv3/
  ├── TestEffectAudioUnit.swift    # AUAudioUnit subclass (DSP)
  ├── EffectViewController.swift   # UI implementation
  ├── AudioUnitFactory.swift       # Factory function for instantiation
  └── Info.plist                   # Extension configuration with AudioComponents
```

## Reference

- Apple's AUv3 Programming Guide: https://developer.apple.com/documentation/audiotoolbox/audio_unit_v3_plug-ins
- AVAudioEngine Documentation: https://developer.apple.com/documentation/avfaudio/avaudioengine
- Core Audio Kit: https://developer.apple.com/documentation/coreaudiokit
