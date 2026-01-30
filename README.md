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
- 🔄 **Load Options**: Compare Out-of-Process vs In-Process loading
- 📈 **History Tracking**: View historical load performance data

## Requirements

- macOS 14.0+ / iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Usage

1. Select a plugin type from the segmented control
2. Choose a plugin from the list
3. Toggle "Out-of-Process" option as needed
4. Click "Load" to load the plugin and measure performance
5. Click "Benchmark x5" to run multiple load tests

## Performance Guidelines

| Load Time | Rating |
|-----------|--------|
| < 200ms | 🟢 Excellent |
| 200-500ms | 🟡 Good |
| > 500ms | 🔴 Needs Optimization |

## License

MIT License
