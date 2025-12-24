import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'dart:io' show File;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:typed_data' show Uint8List;

import '../services/audio_generator.dart';
import '../widgets/presets_grid.dart';
import '../models/preset.dart';

// Conditional import: only on web (Flutter ignores on iOS)
import 'dart:html' as html if (dart.library.io) 'dart:io';

class TherapyHomePage extends StatefulWidget {
  const TherapyHomePage({super.key});

  @override
  State<TherapyHomePage> createState() => _TherapyHomePageState();
}

class _TherapyHomePageState extends State<TherapyHomePage> {
  final AudioPlayer _player = AudioPlayer();

  double durationMin = 5.0;
  double beatFreq = 6.0;
  double carrierFreq = 528.0;
  String toneType = 'hybrid';
  String ambientType = 'pink';
  double toneVolume = 0.25;
  double ambientVolume = 0.75;

  bool isGenerating = false;
  bool isPreviewing = false;
  double generateProgress = 0.0;

  final List<double> brainwaveValues = [2.5, 4.0, 6.0, 10.0, 18.0, 40.0];
  final List<String> brainwaveLabels = [
    'Delta – Deep Sleep (2.5 Hz)',
    'Deep Theta – Healing (4.0 Hz)',
    'Theta – Relaxation (6.0 Hz)',
    'Alpha – Calm Focus (10 Hz)',
    'Beta – Alert Focus (18 Hz)',
    'Gamma – Peak Cognition (40 Hz)',
  ];

  final List<double> solfeggioValues = [0, 174, 285, 396, 417, 528, 639, 741, 852, 963];
  final List<String> solfeggioLabels = [
    'None',
    '174 Hz – Pain Relief',
    '285 Hz – Energy',
    '396 Hz – Release Fear',
    '417 Hz – Change',
    '528 Hz – Transformation',
    '639 Hz – Connection',
    '741 Hz – Expression',
    '852 Hz – Intuition',
    '963 Hz – Consciousness',
  ];

  void applyPreset(Preset p) => setState(() {
        durationMin = kIsWeb ? 1.0 : p.durationMin;
        beatFreq = p.beatFreq;
        carrierFreq = p.carrierFreq;
        toneType = p.toneType;
        ambientType = p.ambientType;
      });

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    if (isPreviewing) {
      await _player.stop();
      setState(() => isPreviewing = false);
      return;
    }

    setState(() => isPreviewing = true);

    try {
      final wav = await AudioGenerator.generateAsync(
        durationSec: 15,
        beatFreq: beatFreq,
        carrierFreq: carrierFreq,
        toneType: toneType,
        ambientType: ambientType,
        toneVolume: toneVolume,
        ambientVolume: ambientVolume,
        onProgress: (_) {},
      );

      await _player.setAudioSource(InMemoryAudioSource(wav));
      await _player.play();

      _player.playerStateStream.listen((state) {
        if (!state.playing && mounted) setState(() => isPreviewing = false);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preview error: $e')));
    }
  }

  Future<void> _generateAndSave() async {
    setState(() {
      isGenerating = true;
      generateProgress = 0.0;
    });

    try {
      final maxDuration = kIsWeb ? 1.0 : 12.0;
      final clampedDuration = durationMin.clamp(1.0, maxDuration);
      final wav = await AudioGenerator.generateAsync(
        durationSec: clampedDuration * 60,
        beatFreq: beatFreq,
        carrierFreq: carrierFreq,
        toneType: toneType,
        ambientType: ambientType,
        toneVolume: toneVolume,
        ambientVolume: ambientVolume,
        onProgress: (progress) {
          if (mounted) setState(() => generateProgress = progress);
        },
      );

      final name = 'Therapy_${toneType[0].toUpperCase()}${toneType.substring(1)}_${beatFreq.toInt()}Hz_${ambientType}_${clampedDuration.round()}min.wav';

      if (kIsWeb) {
        final blob = html.Blob([wav], 'audio/wav');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement;
        anchor.href = url;
        anchor.download = name;
        anchor.click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download started!')));
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File(path.join(dir.path, name));
        await file.writeAsBytes(wav);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Library!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxDuration = kIsWeb ? 1.0 : 12.0;
    durationMin = durationMin.clamp(1.0, maxDuration);

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Track'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Presets', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            PresetsGrid(onPresetSelected: applyPreset),

            const SizedBox(height: 24),

            ExpansionTile(
              title: const Text('Custom Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              initiallyExpanded: false,
              children: [
                const Text('Duration (minutes) – Max 12'),
                if (kIsWeb)
                  const Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      'Browser limit: max 1 minute. Use mobile app for longer tracks.',
                      style: TextStyle(fontSize: 12, color: Colors.orangeAccent),
                    ),
                  ),
                Slider(
                  min: 1.0,
                  max: maxDuration,
                  divisions: maxDuration > 1.0 ? (maxDuration.toInt() - 1) : null,
                  label: durationMin.round().toString(),
                  value: durationMin,
                  onChanged: (v) => setState(() => durationMin = v.clamp(1.0, maxDuration)),
                ),

                const SizedBox(height: 20),
                const Text('Brainwave'),
                DropdownButton<double>(
                  isExpanded: true,
                  value: beatFreq,
                  items: List.generate(brainwaveValues.length, (i) => DropdownMenuItem(value: brainwaveValues[i], child: Text(brainwaveLabels[i]))),
                  onChanged: (v) => setState(() => beatFreq = v!),
                ),

                const SizedBox(height: 20),
                const Text('Solfeggio'),
                DropdownButton<double>(
                  isExpanded: true,
                  value: carrierFreq,
                  items: List.generate(solfeggioValues.length, (i) => DropdownMenuItem(value: solfeggioValues[i], child: Text(solfeggioLabels[i]))),
                  onChanged: (v) => setState(() => carrierFreq = v!),
                ),

                const SizedBox(height: 20),
                const Text('Tone Type'),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'binaural', label: Text('Binaural')),
                    ButtonSegment(value: 'isochronic', label: Text('Isochronic')),
                    ButtonSegment(value: 'hybrid', label: Text('Hybrid')),
                  ],
                  selected: {toneType},
                  onSelectionChanged: (s) => setState(() => toneType = s.first),
                ),

                const SizedBox(height: 20),
                const Text('Ambient'),
                DropdownButton<String>(
                  isExpanded: true,
                  value: ambientType,
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('None')),
                    DropdownMenuItem(value: 'pink', child: Text('Pink Noise')),
                    DropdownMenuItem(value: 'rain', child: Text('Rain')),
                    DropdownMenuItem(value: 'ocean', child: Text('Ocean')),
                    DropdownMenuItem(value: 'forest', child: Text('Forest')),
                  ],
                  onChanged: (v) => setState(() => ambientType = v!),
                ),

                const SizedBox(height: 30),
                const Text('Tone Volume'),
                Slider(min: 0, max: 0.5, value: toneVolume, onChanged: (v) => setState(() => toneVolume = v)),

                const Text('Ambient Volume'),
                Slider(min: 0.5, max: 1.0, value: ambientVolume, onChanged: (v) => setState(() => ambientVolume = v)),
              ],
            ),

            const SizedBox(height: 40),

            if (isGenerating) ...[
              const Center(child: Text('Generating track...')),
              LinearProgressIndicator(value: generateProgress),
              Center(child: Text('${(generateProgress * 100).toStringAsFixed(0)}%')),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: isGenerating ? null : _preview,
                  icon: Icon(isPreviewing ? Icons.stop : Icons.play_arrow),
                  label: Text(isPreviewing ? 'Stop' : 'Preview 15s'),
                ),
                ElevatedButton.icon(
                  onPressed: isGenerating ? null : _generateAndSave,
                  icon: isGenerating ? const CircularProgressIndicator() : const Icon(Icons.save),
                  label: const Text('Generate & Save'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            ),

            const SizedBox(height: 40),
            const Center(child: Text('Headphones recommended', style: TextStyle(color: Colors.white70))),
          ],
        ),
      ),
    );
  }
}