import 'package:flutter/material.dart';
import '../models/resonance_state.dart';
import '../services/preset_service.dart';
import '../services/audio_engine/vibrational_driver.dart';
import '../layers/neuro_optical/optical_modulator.dart';
import '../widgets/resonance_intensity.dart';
import '../domains/sphere_domain.dart';
import '../domains/inner_sphere/inner_sphere.dart';
import '../domains/middle_sphere/middle_sphere.dart';
import '../domains/outer_sphere/outer_sphere.dart';
import 'package:flutter/services.dart' show HapticFeedback;

class ExperienceGeneratorScreen extends StatefulWidget {
  const ExperienceGeneratorScreen({super.key});

  @override
  State<ExperienceGeneratorScreen> createState() => _ExperienceGeneratorScreenState();
}

class _ExperienceGeneratorScreenState extends State<ExperienceGeneratorScreen> {
  final PresetService _presetService = PresetService();
  final VibrationalDriver _driver = VibrationalDriver();

  // Current experience parameters
  double _frequencyHz = 6.0;          // Default theta beat frequency
  String _sphereType = 'inner';
  double _intensity = 1.0;
  String _texture = 'default';
  String _toneType = 'hybrid';
  double _carrierFreq = 528.0;        // Default solfeggio frequency
  String? _activePresetName;
  int _presetMode = 1; // 1 or 2
  double _ultrasonicFreq = 0.0;
  double _noiseLevel = 0.0;

  final List<SphereDomain> _domains = [
    const InnerSphere(),
    const MiddleSphere(),
    const OuterSphere(),
  ];

  SphereDomain get _currentDomain => _domains.firstWhere(
        (d) => d.id == _sphereType,
        orElse: () => const InnerSphere(),
      );

  bool _isPlaying = false;
  bool _isFullscreen = false;
  List<ResonanceState> _savedPresets = [];

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final presets = await _presetService.loadPresets();
    if (mounted) {
      setState(() => _savedPresets = presets);
    }
  }

  Future<void> _startExperience({bool refresh = false}) async {
    if (_isPlaying && !refresh) {
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
      ultrasonicFreq: _ultrasonicFreq,
      noiseLevel: _noiseLevel,
    );

    await _driver.playExperience(state, context);
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
        const SnackBar(content: Text('Preset saved successfully')),
      );
    }
  }

  Future<String?> _showNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name this Resonance Experience'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Deep Theta Rain – 6Hz'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  int _currentStep = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _driver.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black, // Dark, focused background
          appBar: _isFullscreen ? null : AppBar(
            title: const Text('AURA Weaver'),
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: _showSavedResonances,
              ),
            ],
          ),
          body: _isFullscreen ? const SizedBox.shrink() : Column(
            children: [
              _buildProgressIndicator(),
              _buildQuickPresets(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (idx) => setState(() => _currentStep = idx),
                  children: [
                    _buildDomainStep(),
                    _buildToneStep(),
                    _buildTextureStep(),
                    _buildLaunchStep(),
                  ],
                ),
              ),
              _buildNavigationControls(),
            ],
          ),
        ),
        if (_isFullscreen)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  OpticalModulator(
                    frequencyHz: _frequencyHz,
                    intensity: _intensity,
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen_exit, color: Colors.white54, size: 32),
                      onPressed: () => setState(() => _isFullscreen = false),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickPresets() {
    final List<Map<String, dynamic>> quickPresets = [
      {
        'name': 'Deep Theta', 
        'sphere': 'inner', 
        'icon': Icons.nightlight,
        'mode1': {'freq': 4.0, 'carrier': 528.0, 'tone': 'binaural', 'tex': 'deep_sleep', 'noise': 0.7, 'ultra': 0.0},
        'mode2': {'freq': 4.0, 'carrier': 528.0, 'tone': 'hybrid', 'tex': 'dna_repair', 'noise': 0.8, 'ultra': 0.0},
      },
      {
        'name': 'Alpha Calm', 
        'sphere': 'inner', 
        'icon': Icons.spa,
        'mode1': {'freq': 10.0, 'carrier': 417.0, 'tone': 'binaural', 'tex': 'deep_sleep', 'noise': 0.2, 'ultra': 0.0},
        'mode2': {'freq': 10.0, 'carrier': 417.0, 'tone': 'hybrid', 'tex': 'dna_repair', 'noise': 0.4, 'ultra': 0.0},
      },
      {
        'name': 'Cat Purr', 
        'sphere': 'middle', 
        'icon': Icons.pets,
        'mode1': {'freq': 6.0, 'carrier': 639.0, 'tone': 'binaural', 'tex': 'cat_zen', 'noise': 0.1, 'ultra': 0.0},
        'mode2': {'freq': 6.0, 'carrier': 639.0, 'tone': 'hybrid', 'tex': 'bio_harmony', 'noise': 0.3, 'ultra': 0.0},
      },
      {
        'name': 'Forest', 
        'sphere': 'middle', 
        'icon': Icons.forest,
        'mode1': {'freq': 18.0, 'carrier': 741.0, 'tone': 'binaural', 'tex': 'cat_zen', 'noise': 0.4, 'ultra': 0.0},
        'mode2': {'freq': 18.0, 'carrier': 741.0, 'tone': 'hybrid', 'tex': 'bio_harmony', 'noise': 0.6, 'ultra': 0.0},
      },
      {
        'name': 'Mosquito X', 
        'sphere': 'outer', 
        'icon': Icons.bug_report,
        'mode1': {'freq': 40.0, 'carrier': 852.0, 'tone': 'binaural', 'tex': 'mosquito_repellent', 'noise': 0.6, 'ultra': 15000.0},
        'mode2': {'freq': 40.0, 'carrier': 852.0, 'tone': 'hybrid', 'tex': 'mosquito_repellent', 'noise': 0.9, 'ultra': 15000.0},
      },
      {
        'name': 'Dog Whistle', 
        'sphere': 'outer', 
        'icon': Icons.hearing,
        'mode1': {'freq': 30.0, 'carrier': 963.0, 'tone': 'binaural', 'tex': 'sonic_shield', 'noise': 0.5, 'ultra': 20000.0},
        'mode2': {'freq': 30.0, 'carrier': 963.0, 'tone': 'hybrid', 'tex': 'sonic_shield', 'noise': 0.8, 'ultra': 20000.0},
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 24, top: 4),
          child: Text('QUICK RESONANCE', style: TextStyle(fontSize: 10, color: Colors.cyan, letterSpacing: 2)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: quickPresets.map((p) {
              final isSelected = _activePresetName == p['name'];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ActionChip(
                  backgroundColor: isSelected ? Colors.cyan.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  side: BorderSide(color: isSelected ? Colors.cyan : Colors.white10),
                  avatar: Icon(p['icon'] as IconData, size: 16, color: isSelected ? Colors.cyan : Colors.white38),
                  label: Text(p['name'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 12)),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _activePresetName = p['name'] as String;
                      final m = (_presetMode == 1 ? p['mode1'] : p['mode2']) as Map<String, dynamic>;
                      _sphereType = p['sphere'] as String;
                      _frequencyHz = m['freq'] as double;
                      _carrierFreq = m['carrier'] as double;
                      _toneType = m['tone'] as String;
                      _texture = m['tex'] as String;
                      _noiseLevel = m['noise'] as double;
                      _ultrasonicFreq = m['ultra'] as double;
                      _currentStep = 3;
                    });
                    _pageController.animateToPage(3, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
                    if (_isPlaying) _startExperience(refresh: true);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        if (_activePresetName != null) _buildModeToggle(),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          const Text('PRESET MODE', style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 1)),
          const SizedBox(width: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('MODE 1'), icon: Icon(Icons.looks_one, size: 12)),
              ButtonSegment(value: 2, label: Text('MODE 2'), icon: Icon(Icons.looks_two, size: 12)),
            ],
            selected: {_presetMode},
            onSelectionChanged: (s) {
              HapticFeedback.selectionClick();
              setState(() => _presetMode = s.first);
              
              // Define presets locally to re-fetch on mode change (simplified)
              final presetsData = [
                {'name': 'Deep Theta', 'mode1': {'freq': 4.0, 'carrier': 528.0, 'tone': 'binaural', 'tex': 'deep_sleep', 'noise': 0.7, 'ultra': 0.0}, 'mode2': {'freq': 4.0, 'carrier': 528.0, 'tone': 'hybrid', 'tex': 'dna_repair', 'noise': 0.8, 'ultra': 0.0}},
                {'name': 'Alpha Calm', 'mode1': {'freq': 10.0, 'carrier': 417.0, 'tone': 'binaural', 'tex': 'deep_sleep', 'noise': 0.2, 'ultra': 0.0}, 'mode2': {'freq': 10.0, 'carrier': 417.0, 'tone': 'hybrid', 'tex': 'dna_repair', 'noise': 0.4, 'ultra': 0.0}},
                {'name': 'Cat Purr', 'mode1': {'freq': 6.0, 'carrier': 639.0, 'tone': 'binaural', 'tex': 'cat_zen', 'noise': 0.1, 'ultra': 0.0}, 'mode2': {'freq': 6.0, 'carrier': 639.0, 'tone': 'hybrid', 'tex': 'bio_harmony', 'noise': 0.3, 'ultra': 0.0}},
                {'name': 'Forest', 'mode1': {'freq': 18.0, 'carrier': 741.0, 'tone': 'binaural', 'tex': 'cat_zen', 'noise': 0.4, 'ultra': 0.0}, 'mode2': {'freq': 18.0, 'carrier': 741.0, 'tone': 'hybrid', 'tex': 'bio_harmony', 'noise': 0.6, 'ultra': 0.0}},
                {'name': 'Mosquito X', 'mode1': {'freq': 40.0, 'carrier': 852.0, 'tone': 'binaural', 'tex': 'mosquito_repellent', 'noise': 0.6, 'ultra': 15000.0}, 'mode2': {'freq': 40.0, 'carrier': 852.0, 'tone': 'hybrid', 'tex': 'mosquito_repellent', 'noise': 0.9, 'ultra': 15000.0}},
                {'name': 'Dog Whistle', 'mode1': {'freq': 30.0, 'carrier': 963.0, 'tone': 'binaural', 'tex': 'sonic_shield', 'noise': 0.5, 'ultra': 20000.0}, 'mode2': {'freq': 30.0, 'carrier': 963.0, 'tone': 'hybrid', 'tex': 'sonic_shield', 'noise': 0.8, 'ultra': 20000.0}},
              ];
              
              final p = presetsData.firstWhere((item) => item['name'] == _activePresetName);
              final m = (_presetMode == 1 ? p['mode1'] : p['mode2']) as Map<String, dynamic>;
              
              setState(() {
                _frequencyHz = m['freq'] as double;
                _carrierFreq = m['carrier'] as double;
                _toneType = m['tone'] as String;
                _texture = m['tex'] as String;
                _noiseLevel = m['noise'] as double;
                _ultrasonicFreq = m['ultra'] as double;
              });
              if (_isPlaying) _startExperience(refresh: true);
            },
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 10),
              selectedBackgroundColor: Colors.cyan.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.cyan : Colors.white24,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive ? [BoxShadow(color: Colors.cyan.withOpacity(0.5), blurRadius: 4)] : [],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('BACK', style: TextStyle(color: Colors.white70, letterSpacing: 1.2)),
            )
          else
            const SizedBox.shrink(),
          
          if (_currentStep < 3)
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('CONTINUE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildDomainStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Sphere Domain', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
          const SizedBox(height: 8),
          const Text('Choose the environmental focus of this resonance.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 32),
          ..._domains.map((d) => _buildDomainCard(d)).toList(),
        ],
      ),
    );
  }

  Widget _buildDomainCard(SphereDomain domain) {
    final isSelected = _sphereType == domain.id;
    return GestureDetector(
      onTap: () => setState(() {
        _activePresetName = null;
        _sphereType = domain.id;
        _texture = domain.availableTextures.first;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan.withOpacity(0.15) : Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.cyan : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: Colors.cyan.withOpacity(0.2), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Icon(
              domain.id == 'inner' ? Icons.self_improvement : domain.id == 'middle' ? Icons.pets : Icons.shield_outlined,
              size: 32,
              color: isSelected ? Colors.cyan : Colors.white38,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    domain.id.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isSelected ? Colors.cyan : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    domain.id == 'inner' ? 'Healing, DNA Repair, Neural Mist' : domain.id == 'middle' ? 'Animal Zen, Dog Whistle, Bio-Textures' : 'Masking, Mosquito Repellent, Shields',
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.cyan),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String desc, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyan, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Tone Configuration ---
  Widget _buildToneStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tone Synthesis', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
          const SizedBox(height: 32),
          _buildSectionTitle('Interaction Type'),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'binaural', label: Text('Binaural')),
              ButtonSegment(value: 'isochronic', label: Text('Isochronic')),
              ButtonSegment(value: 'hybrid', label: Text('Hybrid')),
            ],
            selected: {_toneType},
            onSelectionChanged: (s) {
              setState(() => _toneType = s.first);
              if (_isPlaying) _startExperience(refresh: true);
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              selectedBackgroundColor: Colors.cyan.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Beat Frequency: ${_frequencyHz.toStringAsFixed(1)} Hz'),
          Slider(
            min: 0.5,
            max: 40.0,
            divisions: 79,
            value: _frequencyHz,
            activeColor: Colors.cyan,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _frequencyHz = v);
              if (_isPlaying) _startExperience(refresh: true);
            },
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Solfeggio Carrier'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [174, 285, 396, 417, 528, 639, 741, 852, 963].map((f) {
              final isSel = _carrierFreq == f.toDouble();
              return ChoiceChip(
                label: Text('$f Hz'),
                selected: isSel,
                onSelected: (val) {
                  if (val) {
                    setState(() => _carrierFreq = f.toDouble());
                    if (_isPlaying) _startExperience(refresh: true);
                  }
                },
                selectedColor: Colors.cyan.withOpacity(0.3),
                backgroundColor: Colors.transparent,
                labelStyle: TextStyle(color: isSel ? Colors.cyan : Colors.white70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Texture Selection ---
  Widget _buildTextureStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Environmental Layer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _currentDomain.availableTextures.length,
            itemBuilder: (ctx, i) {
              final t = _currentDomain.availableTextures[i];
              final isSel = _texture == t;
              return GestureDetector(
                onTap: () => setState(() => _texture = t),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSel ? Colors.cyan.withOpacity(0.15) : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isSel ? Colors.cyan : Colors.white10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    t[0].toUpperCase() + t.substring(1).replaceAll('_', ' '),
                    style: TextStyle(color: isSel ? Colors.cyan : Colors.white70, fontWeight: isSel ? FontWeight.bold : null),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Step 4: Launch Pad ---
  Widget _buildLaunchStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Ready for Resonance', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          
          // Resonance Core (The "Audio Illusion" screen within a screen)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isPlaying ? Colors.cyan.withOpacity(0.5) : Colors.white10),
              boxShadow: _isPlaying ? [BoxShadow(color: Colors.cyan.withOpacity(0.2), blurRadius: 20)] : [],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (_isPlaying)
                  OpticalModulator(
                    frequencyHz: _frequencyHz,
                    intensity: _intensity,
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.offline_bolt_outlined, size: 48, color: Colors.white10),
                        const SizedBox(height: 8),
                        const Text('Ready to Deploy', style: TextStyle(color: Colors.white10)),
                      ],
                    ),
                  ),
                if (_isPlaying)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white38),
                      onPressed: () => setState(() => _isFullscreen = true),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          Text(
            'Sphere: ${_sphereType.toUpperCase()} • Tone: ${_toneType.toUpperCase()} • Texture: ${_texture[0].toUpperCase() + _texture.substring(1)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Intensity Calibration'),
          ResonanceIntensity(
            value: _intensity,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _intensity = v);
              if (_isPlaying) _startExperience(refresh: true);
            },
          ),
          const SizedBox(height: 32),
          _buildMainButton(
            onPressed: _startExperience,
            icon: _isPlaying ? Icons.stop_circle : Icons.offline_bolt,
            label: _isPlaying ? 'CEASE RESONANCE' : 'DEPLOY AURA',
            color: _isPlaying ? Colors.redAccent : Colors.cyan,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _savePreset,
            icon: const Icon(Icons.bookmark_add, color: Colors.white38),
            label: const Text('Save Configuration', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  void _showSavedResonances() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saved Resonances', style: TextStyle(fontSize: 22, color: Colors.white)),
            const SizedBox(height: 20),
            Expanded(
              child: _savedPresets.isEmpty
                  ? const Center(child: Text('Empty', style: TextStyle(color: Colors.white24)))
                  : ListView.builder(
                      itemCount: _savedPresets.length,
                      itemBuilder: (ctx, i) {
                        final p = _savedPresets[i];
                        return Card(
                          color: Colors.white.withOpacity(0.05),
                          child: ListTile(
                            title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('${p.toneType} @ ${p.frequencyHz}Hz', style: const TextStyle(color: Colors.white38)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.cyan),
                            onTap: () {
                              setState(() {
                                _frequencyHz = p.frequencyHz;
                                _sphereType = p.sphereType;
                                _intensity = p.intensity;
                                _texture = p.texture;
                                _toneType = p.toneType;
                                _carrierFreq = p.carrierFreq;
                                _currentStep = 3; // Go to launch page
                              });
                              _pageController.jumpToPage(3);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.white.withOpacity(0.15),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 12,
        shadowColor: (color ?? Colors.cyan).withOpacity(0.4),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.cyan,
        letterSpacing: 2.0,
      ),
    );
  }
}