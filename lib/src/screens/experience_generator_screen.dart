import 'package:flutter/material.dart';
import '../models/resonance_state.dart';
import '../services/preset_service.dart';
import '../services/audio_engine/vibrational_driver.dart';
import '../layers/neuro_optical/optical_modulator.dart';
import '../widgets/resonance_intensity.dart';

class ExperienceGeneratorScreen extends StatefulWidget {
  const ExperienceGeneratorScreen({super.key});

  @override
  State<ExperienceGeneratorScreen> createState() => _ExperienceGeneratorScreenState();
}

class _ExperienceGeneratorScreenState extends State<ExperienceGeneratorScreen> {
  final PresetService _presetService = PresetService();
  final VibrationalDriver _driver = VibrationalDriver();

  double _frequencyHz = 6.0;
  String _sphereType = 'inner';
  double _intensity = 1.0;
  String _texture = 'default';
  String _toneType = 'hybrid';
  double _carrierFreq = 528.0;

  bool _isPlaying = false;
  List<ResonanceState> _savedPresets = [];

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final presets = await _presetService.loadPresets();
    if (mounted) setState(() => _savedPresets = presets);
  }

  Future<void> _startExperience() async {
    if (_isPlaying) {
      await _driver.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    final state = ResonanceState(
      frequencyHz: _frequencyHz,
      sphereType: _sphereType,
      intensity: _intensity,
      texture: _texture,
      toneType: _toneType,
      carrierFreq: _carrierFreq,
    );

    await _driver.playExperience(state);
    if (mounted) setState(() => _isPlaying = true);
  }

  Future<void> _savePreset() async {
    final name = await _showNameDialog();
    if (name == null || name.trim().isEmpty) return;

    final state = ResonanceState(
      name: name.trim(),
      frequencyHz: _frequencyHz,
      sphereType: _sphereType,
      intensity: _intensity,
      texture: _texture,
      toneType: _toneType,
      carrierFreq: _carrierFreq,
    );

    await _presetService.savePreset(state);
    await _loadPresets();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preset "$name" saved')),
      );
    }
  }

  Future<String?> _showNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name this Experience'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Deep Theta Rain – 6Hz'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _driver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        OpticalModulator(frequencyHz: _frequencyHz, intensity: _intensity),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('AURA Resonance Generator')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sphere Domain', style: TextStyle(fontSize: 18)),
                DropdownButton<String>(
                  value: _sphereType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'inner', child: Text('Inner Sphere – ASMR, Binaural, Healing')),
                    DropdownMenuItem(value: 'middle', child: Text('Middle Sphere – Animal Calls, Textures')),
                    DropdownMenuItem(value: 'outer', child: Text('Outer Sphere – Deterrents, Masking')),
                  ],
                  onChanged: (v) => setState(() => _sphereType = v!),
                ),

                const SizedBox(height: 16),

                const Text('Beat Frequency (Hz)'),
                Slider(
                  min: 0.5,
                  max: 40.0,
                  divisions: 79,
                  value: _frequencyHz,
                  label: _frequencyHz.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _frequencyHz = v),
                ),

                const Text('Solfeggio Carrier Frequency'),
                DropdownButton<double>(
                  value: _carrierFreq,
                  isExpanded: true,
                  items: [174, 285, 396, 417, 528, 639, 741, 852, 963]
                      .map((f) => DropdownMenuItem(value: f.toDouble(), child: Text('$f Hz')))
                      .toList(),
                  onChanged: (v) => setState(() => _carrierFreq = v!),
                ),

                const Text('Tone Type'),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'binaural', label: Text('Binaural')),
                    ButtonSegment(value: 'isochronic', label: Text('Isochronic')),
                    ButtonSegment(value: 'hybrid', label: Text('Hybrid')),
                  ],
                  selected: {_toneType},
                  onSelectionChanged: (s) => setState(() => _toneType = s.first),
                ),

                const SizedBox(height: 16),

                const Text('Texture Layer'),
                DropdownButton<String>(
                  value: _texture,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('Ambient Default')),
                    DropdownMenuItem(value: 'binaural_528', child: Text('Binaural 528 Hz')),
                    DropdownMenuItem(value: 'purr', child: Text('Cat Purr')),
                    DropdownMenuItem(value: 'ultrasonic', child: Text('Ultrasonic 18kHz')),
                  ],
                  onChanged: (v) => setState(() => _texture = v!),
                ),

                const SizedBox(height: 16),

                const Text('Resonance Intensity'),
                ResonanceIntensity(value: _intensity, onChanged: (v) => setState(() => _intensity = v)),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _startExperience,
                      icon: Icon(_isPlaying ? Icons.stop_circle : Icons.play_circle),
                      label: Text(_isPlaying ? 'Stop' : 'Generate'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _savePreset,
                      icon: const Icon(Icons.bookmark_add),
                      label: const Text('Save Preset'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                const Text('Saved Presets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _savedPresets.isEmpty
                    ? const Center(child: Text('No presets saved yet'))
                    : Column(
                        children: _savedPresets.map((p) => ListTile(
                              title: Text(p.name),
                              subtitle: Text(
                                '${p.toneType.toUpperCase()} • ${p.frequencyHz.toStringAsFixed(1)} Hz • Carrier ${p.carrierFreq.toStringAsFixed(0)} Hz',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: () {
                                  setState(() {
                                    _frequencyHz = p.frequencyHz;
                                    _sphereType = p.sphereType;
                                    _intensity = p.intensity;
                                    _texture = p.texture;
                                    _toneType = p.toneType;
                                    _carrierFreq = p.carrierFreq;
                                  });
                                  _startExperience();
                                },
                              ),
                            )).toList(),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}