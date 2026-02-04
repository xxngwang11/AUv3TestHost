# Audio Resources

## TestAudio.wav

**Description**: Test audio file for AUv3 plugin testing and demonstration.

**Format**: 
- Sample Rate: 44.1 kHz
- Bit Depth: 16-bit PCM
- Channels: Stereo
- Duration: ~30 seconds

**Content**: The audio file contains a simple musical arpeggio (C major chord notes: C4, E4, G4, C5) generated programmatically as a sine wave. Each note plays for approximately 7.5 seconds with smooth fade-in and fade-out envelopes to prevent clicking.

**Source**: This audio file was generated programmatically using Python for this project.

**License**: Public Domain (CC0) - This audio file is free to use for any purpose without restriction. It was generated specifically for this project and contains no copyrighted material.

**Purpose**: This audio file is used by the AudioEngine to:
1. Test audio playback functionality
2. Demonstrate effect processing through loaded AUv3 effect plugins
3. Provide a consistent test signal for plugin evaluation

**Fallback**: If this file cannot be loaded for any reason, the AudioEngine will automatically generate a 2-second 440Hz sine wave (A4 note) as a fallback audio source.
