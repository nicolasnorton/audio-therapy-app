# Audio Therapy App - LLM Context & Architecture

Last updated: December 30, 2025

## Project Objective
The **AURA (Acoustic-Ultraviolet-Resonance-Atmosphere)** Bio-Interface is a modular sound therapy engine designed to bridge cognitive states and physical environments through resonance.

## Core Architecture (The Weaver)
The app has transitioned from a single-file prototype to a modular **multi-domain architecture**:
- **Sphere Domains**: 3-tiered environmental focus:
    - `InnerSphere`: Healing, DNA Repair (528Hz), ASMR.
    - `MiddleSphere`: Bio-textures (Cat Zen/Purr), Dog Whistles.
    - `OuterSphere`: Shields, Deterrents (Mosquito Repellent/18kHz).
- **VibrationalDriver**: A robust audio engine managing two synchronous layers:
    - **Ambient Layer**: High-quality .mp3 textures (weighted at 85% volume).
    - **Tone Layer**: Programmatic synthesis (weighted at 25% volume) using `ProgrammaticToneSource`.
- **AURA Weaver UI**: A multi-step wizard (`ExperienceGeneratorScreen`) with:
    - **6 Quick Presets**: Global hot-swaps for common resonance states.
    - **Step-by-Step Flow**: Domain Selection → Tone Synthesis → Texture Selection → Launch Pad.

## Key Implementation Details
- **Audio Engine**: Uses `just_audio` with a custom `VibrationalDriver` that implements "Request ID" tracking to prevent sound overlapping during rapid transitions.
- **Tone Synthesis**: Pure Dart generation of Binaural, Isochronic, and Hybrid (Binaural + Isochronic) tones via `ProgrammaticToneSource`.
- **Visuals**: `OpticalModulator` provides frequency-locked visual entrainment during active resonance.
- **State Management**: Uses `ResonanceState` model to encapsulate frequency, intensity, sphere type, and texture.

## Technical Notes for LLMs
- **Modular Domains**: Domain-specific logic (asset mapping, texture lists) lives in `lib/src/domains/`.
- **Mixing Philosophy**: The balance is shifted towards "Atmospheric Textures." Tones should be subtle hums, not dominant sirens.
- **Stability**: Rapidly clicking presets is handled by invalidating old `requestId`s in the `VibrationalDriver`.
- **Assets**: Sounds are organized in `assets/sounds/[inner|middle|outer]/`.

## Development Principles
- **Aesthetic Excellence**: UI must feel "premium," utilizing cyan/dark palettes, glassmorphism, and smooth transitions.
- **Scientific Foundation**: Use Solfeggio frequencies and brainwave ranges (Delta 0.5-4Hz, Theta 4-8Hz, Alpha 8-12Hz, Beta 12-30Hz, Gamma 30-40Hz).
- **Pure Dart**: Logic should remain in Dart/Flutter; minimize platform-specific native plugins unless strictly necessary (like `just_audio`).

## Current Path Mapping
- `lib/src/screens/`: UI layers and Wizards.
- `lib/src/services/audio_engine/`: The core drivers and tone generators.
- `lib/src/domains/`: Definitions for Sphere interaction logic.
- `lib/src/models/`: Shared state objects.

This document serves as the ground truth for LLMs continuing the "AURA Vision" branch development.