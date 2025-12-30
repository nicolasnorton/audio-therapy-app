import 'dart:async';
import 'dart:io' show File;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';

class _GenParams {
  final double durationSec;
  final double beatFreq;
  final double carrierFreq;
  final String toneType;
  final String ambientType;
  final double toneVolume;
  final double ambientVolume;
  final SendPort? sendPort;

  _GenParams({
    required this.durationSec,
    required this.beatFreq,
    required this.carrierFreq,
    required this.toneType,
    required this.ambientType,
    required this.toneVolume,
    required this.ambientVolume,
    this.sendPort,
  });
}

class AudioGenerator {
  static const int sampleRate = 44100;
  static const double pi2 = 2 * pi;

  static void synthesizeSampleToBuffer({
    required int i,
    required Float32List buffer,
    required double sampleRate,
    required double carrierFreq,
    required double beatFreq,
    required String toneType,
    required double toneVolume,
    double ultrasonicFreq = 0.0,
    double noiseLevel = 0.0,
  }) {
    final t = i / sampleRate;

    // Core Tones
    final left = sin(pi2 * carrierFreq * t);
    final right = sin(pi2 * (carrierFreq + beatFreq) * t);
    final carrier = sin(pi2 * carrierFreq * t);

    // Isochronic Modulation
    final isochronic = carrier * (1 + 0.7 * sin(pi2 * beatFreq * t));

    double mainL, mainR;
    if (toneType == 'binaural') {
      mainL = left;
      mainR = right;
    } else if (toneType == 'isochronic') {
      mainL = mainR = isochronic;
    } else {
      mainL = 0.5 * carrier + 0.3 * left + 0.2 * isochronic;
      mainR = 0.5 * carrier + 0.3 * right + 0.2 * isochronic;
    }

    // Ultrasonic Layer (e.g. 15kHz-20kHz)
    double ultra = 0.0;
    if (ultrasonicFreq > 0) {
      ultra = sin(pi2 * ultrasonicFreq * t) * 0.5;
    }

    // Simple White Noise (can be filtered downstream if needed)
    final noise = noiseLevel > 0 ? (Random(i).nextDouble() * 2 - 1) * noiseLevel : 0.0;

    buffer[i * 2] = (mainL * toneVolume + ultra + noise);
    buffer[i * 2 + 1] = (mainR * toneVolume + ultra + noise);
  }

  static Future<Uint8List> generateAsync({
    required double durationSec,
    required double beatFreq,
    required double carrierFreq,
    required String toneType,
    String ambientType = 'pink',
    double toneVolume = 0.25,
    double ambientVolume = 0.75,
    required Function(double) onProgress,
  }) async {
    print("Generating ${durationSec}s track (platform: ${kIsWeb ? 'web (sync)' : 'mobile (isolate)'})");

    final samples = (durationSec * sampleRate).floor();
    final buffer = Float32List(samples * 2);

    final baseCarrier = carrierFreq > 0 ? carrierFreq : 240.0;
    final ambient = ambientType != 'none' ? _generateAmbient(samples, ambientType) : Float32List(samples);

    for (int i = 0; i < samples; i++) {
      if (i % 10000 == 0) onProgress(i / samples.toDouble());

      synthesizeSampleToBuffer(
        i: i,
        buffer: buffer,
        sampleRate: sampleRate.toDouble(),
        carrierFreq: baseCarrier,
        beatFreq: beatFreq,
        toneType: toneType,
        toneVolume: toneVolume,
      );

      final fade = i < 22050 ? i / 22050.0 : i > samples - 22050 ? (samples - i) / 22050.0 : 1.0;

      buffer[i * 2] = (buffer[i * 2] + ambient[i] * ambientVolume) * fade;
      buffer[i * 2 + 1] = (buffer[i * 2 + 1] + ambient[i] * ambientVolume) * fade;
    }

    onProgress(1.0);
    return encodeWav(buffer);
  }

  static Float32List _generateAmbient(int samples, String type) {
    final rnd = Random();
    final noise = Float32List(samples);

    if (type == 'pink') {
      double b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
      for (int i = 0; i < samples; i++) {
        final w = rnd.nextDouble() * 2 - 1;
        b0 = 0.99886 * b0 + w * 0.0555179;
        b1 = 0.99332 * b1 + w * 0.0750759;
        b2 = 0.96900 * b2 + w * 0.1538520;
        b3 = 0.86650 * b3 + w * 0.3104856;
        b4 = 0.55000 * b4 + w * 0.5329522;
        b5 = -0.7616 * b5 + w * 0.0168980;
        noise[i] = b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362;
        b6 = w * 0.115926;
      }
    } else if (type == 'rain' || type == 'forest') {
      final decay = type == 'forest' ? 5.0 : 2.0;
      for (int i = 0; i < samples; i++) {
        noise[i] = (rnd.nextDouble() * 2 - 1) * exp(-i / sampleRate / decay);
      }
    } else if (type == 'ocean') {
      for (int i = 0; i < samples; i++) {
        final t = i / sampleRate;
        noise[i] = 0.4 * sin(pi2 * 0.13 * t) +
                   0.25 * sin(pi2 * 0.19 * t + 1.5) +
                   0.15 * (rnd.nextDouble() * 2 - 1);
      }
    }

    double maxAmp = noise.fold(0.0, (max, v) => v.abs() > max ? v.abs() : max);
    if (maxAmp > 0) {
      for (int i = 0; i < samples; i++) noise[i] /= maxAmp;
    }

    return noise;
  }

  static Uint8List encodeWav(Float32List samples) {
    final bytes = BytesBuilder();
    final dataSize = samples.length * 4;
    final fileSize = 36 + dataSize;

    bytes.add('RIFF'.codeUnits);
    bytes.add(int32(fileSize));
    bytes.add('WAVE'.codeUnits);
    bytes.add('fmt '.codeUnits);
    bytes.add(int32(16));
    bytes.add(int16(3));
    bytes.add(int16(2));
    bytes.add(int32(sampleRate));
    bytes.add(int32(sampleRate * 8));
    bytes.add(int16(8));
    bytes.add(int16(32));
    bytes.add('data'.codeUnits);
    bytes.add(int32(dataSize));
    bytes.add(samples.buffer.asUint8List());

    return bytes.toBytes();
  }

  static List<int> int32(int v) => [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF];
  static List<int> int16(int v) => [v & 0xFF, (v >> 8) & 0xFF];
}

class InMemoryAudioSource extends StreamAudioSource {
  final Uint8List data;

  InMemoryAudioSource(this.data);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
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
}