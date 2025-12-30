import 'package:flutter/cupertino.dart' show Text;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show BuildContext, ScaffoldMessenger, SnackBar, Colors;
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';
import 'dart:io' show Platform; // ← Fixes Platform.isIOS
import 'dart:math' as math;

import '../../models/resonance_state.dart';
import '../../domains/sphere_domain.dart';
import '../../domains/inner_sphere/inner_sphere.dart';
import '../../domains/middle_sphere/middle_sphere.dart';
import '../../domains/outer_sphere/outer_sphere.dart';
import 'programmatic_tone_source.dart';

class VibrationalDriver {
  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _tonePlayer = AudioPlayer();
  bool _isProcessing = false;
  int _activeRequestId = 0;

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> playExperience(ResonanceState state, BuildContext context) async {
    final requestId = ++_activeRequestId;
    _isProcessing = true;

    try {
      // 1. Setup Ambient / Texture Layer
      final List<SphereDomain> domains = [
        const InnerSphere(),
        const MiddleSphere(),
        const OuterSphere(),
      ];

      final domain = domains.firstWhere(
        (d) => d.id == state.sphereType,
        orElse: () => const InnerSphere(),
      );

      final assetPath = domain.mapTextureToAsset(state.texture);

      if (!await _assetExists(assetPath)) {
        throw Exception('Audio file missing: $assetPath');
      }

      // Check if another request has superseded this one
      if (requestId != _activeRequestId) return;

      // 1b. Load assets with interruption handling
      try {
        await _ambientPlayer.setAsset(assetPath);
        if (requestId != _activeRequestId) return;
        
        await _ambientPlayer.setVolume(state.intensity.clamp(0.0, 1.0) * 0.85);
        await _ambientPlayer.setLoopMode(LoopMode.all);
      } catch (e) {
        if (!e.toString().contains('interrupted') && !e.toString().contains('abort')) {
          rethrow;
        }
        return; // Superseded
      }

      // 2. Setup Programmatic Tone Layer
      final toneSource = ProgrammaticToneSource(
        beatFreq: state.frequencyHz,
        carrierFreq: state.carrierFreq,
        toneType: state.toneType,
        volume: 0.25 * state.intensity.clamp(0.0, 1.0),
        ultrasonicFreq: state.ultrasonicFreq,
        noiseLevel: state.noiseLevel,
      );

      if (requestId != _activeRequestId) return;

      try {
        await _tonePlayer.setAudioSource(toneSource);
        if (requestId != _activeRequestId) return;
        
        await _tonePlayer.setLoopMode(LoopMode.all);
      } catch (e) {
        if (!e.toString().contains('interrupted') && !e.toString().contains('abort')) {
          rethrow;
        }
        return; // Superseded
      }

      if (requestId != _activeRequestId) return;

      // 3. Sync and Start
      await Future.wait([
        _ambientPlayer.play(),
        _tonePlayer.play(),
      ]);

      print('Experience active: ${state.texture} @ ${state.carrierFreq}Hz');
    } catch (e) {
      // Only show error if this is still the active request
      if (requestId == _activeRequestId) {
        print('Audio error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Audio Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (requestId == _activeRequestId) _isProcessing = false;
    }
  }

  Future<void> stop() async {
    // Invalidate any ongoing play requests
    _activeRequestId++;
    
    try {
      // Immediate volume drop to zero before the async stop() call
      // This solves the "doesn't stop" perception issue
      await Future.wait([
        _ambientPlayer.setVolume(0.0),
        _tonePlayer.setVolume(0.0),
      ]);

      await Future.wait([
        _ambientPlayer.stop(),
        _tonePlayer.stop(),
      ]);
      
      _isProcessing = false;
    } catch (e) {
      print('Stop error: $e');
    }
  }

  void dispose() {
    _activeRequestId = -1; // Invalidate all
    _ambientPlayer.dispose();
    _tonePlayer.dispose();
  }
}