import 'dart:io' show File;
import 'dart:math';
import 'dart:typed_data';

// Conditional import for web download
import 'dart:html' as html if (dart.library.io) '';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() => runApp(const AudioTherapyApp());

class AudioTherapyApp extends StatelessWidget {
  const AudioTherapyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Audio Therapy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A001F),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A0033)),
        ),
        home: const MainScreen(),
      );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const TherapyHomePage(),
      kIsWeb ? const WebLibraryMessage() : const LibraryPage(),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Create'),
            NavigationDestination(icon: Icon(Icons.library_music), label: 'Library'),
          ],
        ),
      );
}

class WebLibraryMessage extends StatelessWidget {
  const WebLibraryMessage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Library'), centerTitle: true),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_download, size: 80, color: Colors.white54),
              SizedBox(height: 20),
              Text('Tracks are downloaded!', style: TextStyle(fontSize: 20)),
              Text('Check your Downloads folder', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
}

class TherapyHomePage extends StatefulWidget {
  const TherapyHomePage({super.key});
  @override
  State<TherapyHomePage> createState() => _TherapyHomePageState();
}

class _TherapyHomePageState extends State<TherapyHomePage> {
  final AudioPlayer _player = AudioPlayer();

  double durationMin = 10.0;
  double beatFreq = 6.0;
  double carrierFreq = 528.0;
  String toneType = 'hybrid';
  String ambientType = 'pink';
  double toneVolume = 0.25;
  double ambientVolume = 0.75;

  bool isGenerating = false;
  bool isPreviewing = false;

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

  final List<Preset> presets = [
    Preset('Deep Sleep', Icons.bedtime, Colors.indigo, 6, 2.5, 174, 'hybrid', 'pink'),
    Preset('Relaxation', Icons.spa, Colors.teal, 4, 6.0, 528, 'hybrid', 'rain'),
    Preset('Focus Flow', Icons.lightbulb, Colors.amber, 5, 10.0, 741, 'binaural', 'ocean'),
    Preset('Anxiety Relief', Icons.self_improvement, Colors.green, 3, 6.0, 396, 'hybrid', 'forest'),
    Preset('Healing', Icons.favorite, Colors.purple, 4, 4.0, 528, 'hybrid', 'pink'),
    Preset('Meditation', Icons.self_improvement_outlined, Colors.deepPurple, 8, 4.0, 417, 'isochronic', 'ocean'),
  ];

  void applyPreset(Preset p) => setState(() {
        durationMin = p.durationMin;
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
    final wav = AudioGenerator.generate(
      durationSec: 15,
      beatFreq: beatFreq,
      carrierFreq: carrierFreq,
      toneType: toneType,
      ambientType: ambientType,
      toneVolume: toneVolume,
      ambientVolume: ambientVolume,
    );
    await _player.setAudioSource(InMemoryAudioSource(wav));
    await _player.play();
    _player.playerStateStream.listen((s) => !s.playing && mounted ? setState(() => isPreviewing = false) : null);
  }

  Future<void> _generateAndSave() async {
    setState(() => isGenerating = true);
    final wav = AudioGenerator.generate(
      durationSec: durationMin * 60,
      beatFreq: beatFreq,
      carrierFreq: carrierFreq,
      toneType: toneType,
      ambientType: ambientType,
      toneVolume: toneVolume,
      ambientVolume: ambientVolume,
    );
    final name = 'Therapy_${toneType[0].toUpperCase()}${toneType.substring(1)}_${beatFreq.toInt()}Hz_${ambientType}_${durationMin.round()}min.wav';

    if (kIsWeb) {
      final dataUri = Uri.dataFromBytes(wav, mimeType: 'audio/wav').toString();
      final anchor = html.AnchorElement(href: dataUri)
        ..setAttribute('download', name)
        ..click();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download started!')));
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(wav);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Library!')));
    }
    setState(() => isGenerating = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create New Track'), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quick Presets', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: presets.length,
                itemBuilder: (_, i) {
                  final p = presets[i];
                  return InkWell(
                    onTap: () => applyPreset(p),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [p.color, p.color.withOpacity(0.8)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: p.color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(p.icon, size: 32, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          p.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ]),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),
              const Divider(),

              const Text('Custom Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              const Text('Duration (minutes) – Max 12'),
              Slider(min: 1, max: 12, divisions: 11, label: durationMin.round().toString(), value: durationMin, onChanged: (v) => setState(() => durationMin = v)),

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

              const SizedBox(height: 40),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
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
              ]),

              const SizedBox(height: 40),
              const Center(child: Text('Headphones recommended', style: TextStyle(color: Colors.white70))),
            ],
          ),
        ),
      );
}

class Preset {
  final String title;
  final IconData icon;
  final Color color;
  final double durationMin, beatFreq, carrierFreq;
  final String toneType, ambientType;
  const Preset(this.title, this.icon, this.color, this.durationMin, this.beatFreq, this.carrierFreq, this.toneType, this.ambientType);
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final AudioPlayer _player = AudioPlayer();
  List<File> tracks = [];

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.wav')).toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    setState(() => tracks = files);
  }

  Future<void> _playTrack(File file) async {
    await _player.setFilePath(file.path);
    await _player.play();
  }

  Future<void> _deleteTrack(File file) async {
    await file.delete();
    _loadTracks();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Library'), centerTitle: true),
        body: tracks.isEmpty
            ? const Center(child: Text('No tracks yet.\nGenerate some!', style: TextStyle(fontSize: 18, color: Colors.white60)))
            : ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (_, i) {
                  final file = tracks[i];
                  final name = path.basename(file.path);
                  return ListTile(
                    leading: const Icon(Icons.music_note, color: Colors.teal),
                    title: Text(name, style: const TextStyle(fontSize: 14)),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteTrack(file)),
                    onTap: () => _playTrack(file),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(child: const Icon(Icons.refresh), onPressed: _loadTracks),
      );
}

class AudioGenerator {
  static const int sampleRate = 44100;

  static Uint8List generate({
    required double durationSec,
    required double beatFreq,
    required double carrierFreq,
    required String toneType,
    String ambientType = 'pink',
    double toneVolume = 0.25,
    double ambientVolume = 0.75,
  }) {
    final samples = (durationSec * sampleRate).floor();
    final t = List.generate(samples, (i) => i / sampleRate);
    final baseCarrier = carrierFreq > 0 ? carrierFreq : 240.0;

    final carrier = List.generate(samples, (i) => sin(2 * pi * baseCarrier * t[i]));
    final left = List.generate(samples, (i) => sin(2 * pi * baseCarrier * t[i]));
    final right = List.generate(samples, (i) => sin(2 * pi * (baseCarrier + beatFreq) * t[i]));

    final isochronic = List<double>.from(carrier);
    const modDepth = 0.14;
    for (int i = 0; i < samples; i++) isochronic[i] *= 1 + modDepth * sin(2 * pi * beatFreq * t[i]);

    List<double> mainL, mainR;
    if (toneType == 'binaural') {
      mainL = left;
      mainR = right;
    } else if (toneType == 'isochronic') {
      mainL = mainR = isochronic;
    } else {
      mainL = List.filled(samples, 0);
      mainR = List.filled(samples, 0);
      for (int i = 0; i < samples; i++) {
        mainL[i] = 0.85 * carrier[i] + 0.12 * left[i] + 0.03 * isochronic[i];
        mainR[i] = 0.85 * carrier[i] + 0.12 * right[i] + 0.03 * isochronic[i];
      }
    }

    for (int i = 0; i < samples; i++) {
      mainL[i] *= toneVolume;
      mainR[i] *= toneVolume;
    }

    final ambient = _generateAmbient(samples, t, ambientType);
    for (int i = 0; i < samples; i++) ambient[i] *= ambientVolume;

    final out = Float32List(samples * 2);
    for (int i = 0; i < samples; i++) {
      out[i * 2] = mainL[i] + ambient[i];
      out[i * 2 + 1] = mainR[i] + ambient[i];
    }
    return _encodeWav(out);
  }

  static List<double> _generateAmbient(int samples, List<double> t, String type) {
    final rnd = Random();
    final noise = List<double>.filled(samples, 0);

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
    } else if (type == 'rain') {
      for (int i = 0; i < samples; i++) noise[i] = (rnd.nextDouble() * 2 - 1) * exp(-t[i] * 2);
    } else if (type == 'ocean') {
      for (int i = 0; i < samples; i++) {
        noise[i] = 0.4 * sin(2 * pi * 0.13 * t[i]) + 0.25 * sin(2 * pi * 0.19 * t[i] + 1.5) + 0.15 * (rnd.nextDouble() * 2 - 1);
      }
    } else if (type == 'forest') {
      for (int i = 0; i < samples; i++) noise[i] = 0.6 * (rnd.nextDouble() * 2 - 1) * exp(-t[i] / 5);
    }

    final max = noise.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
    if (max > 0) for (int i = 0; i < samples; i++) noise[i] /= max;
    return noise;
  }

  static Uint8List _encodeWav(Float32List samples) {
    final bytes = BytesBuilder();
    final dataSize = samples.length * 4;
    final fileSize = 36 + dataSize;

    bytes.add('RIFF'.codeUnits);
    bytes.add(_int32(fileSize));
    bytes.add('WAVE'.codeUnits);
    bytes.add('fmt '.codeUnits);
    bytes.add(_int32(16));
    bytes.add(_int16(3));
    bytes.add(_int16(2));
    bytes.add(_int32(sampleRate));
    bytes.add(_int32(sampleRate * 8));
    bytes.add(_int16(8));
    bytes.add(_int16(32));
    bytes.add('data'.codeUnits);
    bytes.add(_int32(dataSize));
    bytes.add(samples.buffer.asUint8List());
    return bytes.toBytes();
  }

  static List<int> _int32(int v) => [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, v >> 24];
  static List<int> _int16(int v) => [v & 0xFF, v >> 8];
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