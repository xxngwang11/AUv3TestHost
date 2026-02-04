# Quick Start: Adding Plugin Targets in Xcode

This is a condensed reference for quickly adding the plugin targets to the Xcode project.

## Prerequisites

All source files are ready in:
- `TestPluginContainer/` (3 files)
- `TestEffectAUv3/` (4 files)

## Step-by-Step

### 1. Open Project
```bash
open AUv3TestHost.xcodeproj
```

### 2. Add Container App Target

1. **File → New → Target**
2. **iOS → App** (not "App Extension")
3. **Product Name:** `TestPluginContainer`
4. **Bundle ID:** `com.test.TestPluginContainer`
5. **Interface:** SwiftUI
6. **Language:** Swift
7. Click **Finish** (don't activate scheme yet)

### 3. Configure Container App

1. Select **TestPluginContainer** target
2. **General tab:**
   - Deployment Target: **iOS 17.0**
   - iPhone, iPad (both checked)
3. **Build Settings tab:**
   - Info.plist File: `TestPluginContainer/Info.plist`
4. **Build Phases → Compile Sources:**
   - Add `TestPluginContainer/ContainerApp.swift`
   - Add `TestPluginContainer/ContentView.swift`

### 4. Add Extension Target

1. **File → New → Target**
2. **iOS → App Extension**
3. Choose template: **Generic** or **Audio Unit** (either works)
4. **Product Name:** `TestEffectAUv3`
5. **Bundle ID:** `com.test.TestPluginContainer.TestEffectAUv3`
6. **Embed in:** TestPluginContainer
7. Click **Finish** → **Activate** scheme when prompted

### 5. Configure Extension

1. Select **TestEffectAUv3** target
2. **General tab:**
   - Deployment Target: **iOS 17.0**
   - iPhone, iPad (both checked)
   - Verify embedded in TestPluginContainer
3. **Build Settings tab:**
   - Info.plist File: `TestEffectAUv3/Info.plist`
   - Skip Install: **YES**
4. **Build Phases → Compile Sources:**
   - Add `TestEffectAUv3/TestEffectAudioUnit.swift`
   - Add `TestEffectAUv3/EffectViewController.swift`
   - Add `TestEffectAUv3/AudioUnitFactory.swift`

### 6. Verify

1. **TestPluginContainer** target:
   - Build Phases → Embed Foundation Extensions
   - Should list: `TestEffectAUv3.appex`

2. **Project Navigator:**
   - Should see 3 targets: AUv3TestHost, TestPluginContainer, TestEffectAUv3
   - All source files in correct groups

3. **Schemes:**
   - Should have schemes for all 3 targets
   - Select TestPluginContainer or AUv3TestHost to build

### 7. Build Test

1. Select **TestPluginContainer** scheme
2. Choose iOS device (not simulator)
3. **Product → Build** (⌘B)
4. Should build successfully

5. Select **AUv3TestHost** scheme  
6. **Product → Build** (⌘B)
7. Should build successfully

## Testing

1. Run **TestPluginContainer** once on device
2. Close it (plugin is now registered)
3. Run **AUv3TestHost** on same device
4. Tap **"Refresh Plugins"**
5. Select **"Effect"** type
6. Find **"TestCompany: Test Effect"**
7. Tap to load → UI should appear

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't find source files | Use "Add Files" to add from TestPluginContainer/ and TestEffectAUv3/ folders |
| Bundle ID wrong | Check it matches: com.test.TestPluginContainer.TestEffectAUv3 |
| Extension not embedded | Check TestPluginContainer → Build Phases → Embed Extensions |
| Build fails | Verify deployment target is iOS 17.0 for all targets |
| Plugin not found | Run container app once, then reboot device |

## Key Bundle Identifiers

- AUv3TestHost: `com.test.AUv3TestHost`
- TestPluginContainer: `com.test.TestPluginContainer`
- TestEffectAUv3: `com.test.TestPluginContainer.TestEffectAUv3`

## Important Files

- `TestEffectAUv3/Info.plist` - Contains AudioComponents configuration
- All `.swift` files must be added to their respective targets
- No additional frameworks needed

## Next Steps

After successful build:
1. Deploy to real iOS device (17.0+)
2. Install TestPluginContainer
3. Test in AUv3TestHost
4. Adjust gain slider (0.0 - 2.0)
5. Toggle bypass switch
6. Play test audio to verify processing

See **PLUGIN_TESTING.md** for detailed testing procedures.
