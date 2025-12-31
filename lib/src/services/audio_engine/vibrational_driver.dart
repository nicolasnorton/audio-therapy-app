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
  static final VibrationalDriver _instance = VibrationalDriver._internal();
  factory VibrationalDriver() => _instance;
  VibrationalDriver._internal();

  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _tonePlayer = AudioPlayer();
  
  final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

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
    
    _logger.i('🎵 Starting Experience: ${state.name} [ID:$requestId]\n'
              '   • Carrier: ${state.carrierFreq}Hz\n'
              '   • Beat: ${state.frequencyHz}Hz\n'
              '   • Tone: ${state.toneType}\n'
              '   • Texture: ${state.texture}\n'
              '   • Ultrasonic: ${state.ultrasonicFreq}Hz');

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
      _logger.d('   👉 Loading Ambient Asset: $assetPath');
      final loadStart = DateTime.now();

      if (!await _assetExists(assetPath)) {
        throw Exception('Audio file missing: $assetPath');
      }

      if (requestId != _activeRequestId) {
          _logger.w('   ⚠️ Aborting: Request ID mismatch before asset load.');
          return;
      }

      try {
        await _ambientPlayer.setAsset(assetPath);
        if (requestId != _activeRequestId) {
             _logger.w('   ⚠️ Aborting: Request ID mismatch after asset load.');
             return;
        }
        
        await _ambientPlayer.setVolume(state.intensity.clamp(0.0, 1.0) * 0.95);
        await _ambientPlayer.setLoopMode(LoopMode.all);
        _logger.d('   ✅ Ambient Loaded in ${DateTime.now().difference(loadStart).inMilliseconds}ms');
      } catch (e) {
        if (!e.toString().contains('interrupted') && !e.toString().contains('abort')) {
          _logger.e('   ❌ Ambient Load Error', error: e);
          rethrow;
        }
        return; // Superseded
      }

      // 2. Setup Programmatic Tone Layer
      _logger.d('   👉 Generating Tone Buffer...');
      final genStart = DateTime.now();
      
      final toneSource = ProgrammaticToneSource(
        beatFreq: state.frequencyHz,
        carrierFreq: state.carrierFreq,
        toneType: state.toneType,
        volume: 0.12 * state.intensity.clamp(0.0, 1.0),
        ultrasonicFreq: state.ultrasonicFreq,
        noiseLevel: state.noiseLevel,
      );

      if (requestId != _activeRequestId) return;

      try {
        await _tonePlayer.setAudioSource(toneSource);
        if (requestId != _activeRequestId) {
             _logger.w('   ⚠️ Aborting: Request ID mismatch after tone gen.');
             return;
        }
        
        await _tonePlayer.setLoopMode(LoopMode.all);
        _logger.d('   ✅ Tone Generated in ${DateTime.now().difference(genStart).inMilliseconds}ms');
      } catch (e) {
        if (!e.toString().contains('interrupted') && !e.toString().contains('abort')) {
           _logger.e('   ❌ Tone Gen Error', error: e);
           rethrow;
        }
        return; // Superseded
      }

      if (requestId != _activeRequestId) return;

      // 3. Sync and Start - FINAL SAFETY CHECK
      if (requestId == _activeRequestId) {
        await Future.wait([
          _ambientPlayer.play(),
          _tonePlayer.play(),
        ]);
        _logger.i('   🚀 Experience Active & Playing [ID:$requestId]');
      }
    } catch (e) {
      if (requestId == _activeRequestId) {
        _logger.e('   ❌ Audio Engine Error', error: e);
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
    _logger.i('🛑 Stopping Resonance');
    // Invalidate any ongoing play requests IMMEDIATELY
    _activeRequestId++;
    _isProcessing = false;
    
    try {
      await Future.wait([
        _ambientPlayer.setVolume(0.0),
        _tonePlayer.setVolume(0.0),
      ]);

      await Future.wait([
        _ambientPlayer.stop(),
        _tonePlayer.stop(),
      ]);
      _logger.d('   ✅ Players Stopped');
    } catch (e) {
      _logger.e('   ❌ Stop Error', error: e);
    }
  }

  void dispose() {
    _activeRequestId = -1; // Invalidate all
    _ambientPlayer.dispose();
    _tonePlayer.dispose();
  }
}