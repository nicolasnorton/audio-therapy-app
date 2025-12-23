
### Updated llms.md (for LLM prompting / project documentation)

```markdown
# Audio Therapy App - LLM Prompting Guide

Last updated: December 23, 2025

## Project Overview
Cross-platform Flutter app for generating personalized sound therapy tracks:
- Binaural beats / isochronic tones / hybrid
- Brainwave frequencies (delta to gamma)
- Solfeggio frequencies
- Ambient sounds (pink, rain, ocean, forest)
- Presets + custom settings
- 15s preview + full save (1–12 min)
- Library management

## Current Implementation Details
- Single-file `main.dart` (for simplicity during development)
- Audio generation: Pure Dart synthesis (sin waves + amplitude modulation)
- Mobile: `Isolate` for background generation (no UI freeze)
- Web: Synchronous generation, max 1 minute (due to Dart web limitations)
- UI: Dark theme, ExpansionTile for collapsible custom settings
- Playback: `just_audio` + in-memory `StreamAudioSource`
- Save: Documents directory (mobile), browser download (web)

## Key Technical Notes for LLMs
- **No Web Workers** currently (Dart web interop + structured clone issues with ArrayBuffer transfer)
- **Slider clamping** on web: max 1.0, divisions null, durationMin clamped to 1.0
- **Presets** on web: durationMin forced to 1.0 when selected
- **Ambient on web**: Simplified (pink noise approximation)
- **Dependencies**: just_audio, path_provider, path

## Prompting Tips for Future Improvements
When asking LLMs for code changes:
- Specify platform (web vs mobile) if relevant
- Mention current single-file structure
- Request modularization (src/services/audio_generator.dart, etc.)
- Ask for background playback (`just_audio_background`)
- Request fade-out on track end
- Specify "no external audio generation libs" (keep pure Dart)

## Known Limitations
- Web: 1-minute max (browser single-thread performance)
- No background playback yet (app must stay open)
- Ambient sounds simplified on web

This document is for LLM context when continuing development.