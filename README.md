# Audio Therapy App

A personalized sound therapy Flutter app that generates binaural beats, isochronic tones, hybrid audio, and ambient sounds (pink noise, rain, ocean, forest) combined with solfeggio frequencies.

Features brainwave entrainment (delta to gamma), quick presets, custom settings, 15-second preview, full track generation, and a library for saved tracks.

## Features
- **Brainwave Entrainment**: Delta (2.5 Hz), Theta (4–6 Hz), Alpha (10 Hz), Beta (18 Hz), Gamma (40 Hz)
- **Solfeggio Frequencies**: 174 Hz to 963 Hz (or none)
- **Tone Types**: Binaural, Isochronic, Hybrid
- **Ambient Sounds**: Pink noise, rain, ocean, forest (or none)
- **Quick Presets**: Deep Sleep, Relaxation, Focus Flow, Anxiety Relief, Healing, Meditation
- **Generation**: 1–12 minutes (browser limit: 1 min max)
- **Preview**: 15-second sample playback
- **Library**: Save, play, delete tracks
- **Cross-Platform**: iOS, Android, Web (Chrome/Edge/Safari), macOS, Windows
- **Performance**: Background generation on mobile (no UI freeze), synchronous on web (short tracks only)

## Current Status (Dec 23, 2025)
- **Fully working** on iOS/Android (long tracks with smooth progress)
- **Stable on web** (preview + up to 1 min tracks; longer shows clear warning)
- **UI**: Presets + buttons always visible (custom settings collapsible via ExpansionTile)
- **Audio**: Fade-in/out, volume controls, headphone recommendation
- **No Web Workers** (removed due to Dart web interop limitations with binary data transfer)

## Installation & Run
1. Clone the repo
2. Install dependencies
   ```bash
   flutter pub get