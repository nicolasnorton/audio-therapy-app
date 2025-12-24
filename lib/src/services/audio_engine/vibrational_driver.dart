import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';
import 'dart:math' as math;

import '../../models/resonance_state.dart';

class VibrationalDriver {
  final AudioPlayer _player = AudioPlayer();

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> playExperience(ResonanceState state) async {
    try {
      // Map texture to your actual file names
      String assetPath;
      switch (state.texture) {
        case 'default':
          assetPath = 'assets/sounds/inner/ambient_default.mp3';
          break;
        case 'binaural_528':
          assetPath = 'assets/sounds/inner/binaural_528.mp3';
          break;
        case 'purr':
          assetPath = 'assets/sounds/middle/cat_purr.mp3';
          break;
        case 'ultrasonic':
          assetPath = 'assets/sounds/outer/ultrasonic_18khz.mp3';
          break;
        default:
          assetPath = 'assets/sounds/inner/ambient_default.mp3';
      }

      if (!await _assetExists(assetPath)) {
        throw Exception('Audio file not found: $assetPath');
      }

      await _player.setAsset(assetPath);
      _player.setVolume(state.intensity);

      // Biomimetic pitch shift
      final easedPitch = 1.0 + math.sin(state.frequencyHz / 1000) * 0.2;
      _player.setPitch(easedPitch);

      await _player.setLoopMode(LoopMode.all);
      await _player.play();
    } catch (e) {
      print('Audio error: $e');
      // You can show SnackBar here if you pass context
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}