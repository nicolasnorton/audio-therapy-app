import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute;
import 'package:just_audio/just_audio.dart';
import '../audio_generator.dart';

class ProgrammaticToneSource extends StreamAudioSource {
  final double beatFreq;
  final double carrierFreq;
  final String toneType;
  final double volume;
  final double ultrasonicFreq;
  final double noiseLevel;

  ProgrammaticToneSource({
    required this.beatFreq,
    required this.carrierFreq,
    required this.toneType,
    required this.volume,
    this.ultrasonicFreq = 0.0,
    this.noiseLevel = 0.0,
  });

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    const double duration = 4.0;
    final data = await compute(_generateWavBufferIsolate, {
      'duration': duration,
      'carrier': carrierFreq,
      'beat': beatFreq,
      'type': toneType,
      'volume': volume,
      'ultra': ultrasonicFreq,
      'noise': noiseLevel,
    });
    
    start ??= 0;
    end ??= data.length;
    
    return StreamAudioResponse(
      sourceLength: data.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(data.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }

  static Uint8List _generateWavBufferIsolate(Map<String, dynamic> params) {
    final double durationSec = params['duration'];
    final double carrierFreq = params['carrier'];
    final double beatFreq = params['beat'];
    final String toneType = params['type'];
    final double volume = params['volume'];
    final double ultra = params['ultra'];
    final double noise = params['noise'];

    const int sampleRate = 44100;
    final int samples = (durationSec * sampleRate).floor();
    final buffer = Float32List(samples * 2);

    final rnd = Random();
    double carrierPhase = 0.0;
    double beatPhase = 0.0;
    const double pi2 = 2 * pi;
    final carrierIncr = (pi2 * carrierFreq) / sampleRate;
    final beatIncr = (pi2 * beatFreq) / sampleRate;

    for (int i = 0; i < samples; i++) {
      AudioGenerator.synthesizeSampleToBuffer(
        i: i,
        buffer: buffer,
        sampleRate: sampleRate.toDouble(),
        carrierPhase: carrierPhase,
        beatPhase: beatPhase,
        toneType: toneType,
        toneVolume: volume,
        ultrasonicFreq: ultra,
        noiseLevel: noise,
        rnd: rnd,
      );

      carrierPhase += carrierIncr;
      beatPhase += beatIncr;
      if (carrierPhase > pi2) carrierPhase -= pi2;
      if (beatPhase > pi2) beatPhase -= pi2;
    }

    return AudioGenerator.encodeWav(buffer);
  }
}
