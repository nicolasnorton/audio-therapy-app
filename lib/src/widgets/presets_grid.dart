import 'package:flutter/material.dart';

import '../models/preset.dart';

class PresetsGrid extends StatelessWidget {
  final Function(Preset) onPresetSelected;

  const PresetsGrid({super.key, required this.onPresetSelected});

  static const List<Preset> presets = [
    Preset('Deep Sleep', Icons.bedtime, Colors.indigo, 6, 2.5, 174, 'hybrid', 'pink'),
    Preset('Relaxation', Icons.spa, Colors.teal, 4, 6.0, 528, 'hybrid', 'rain'),
    Preset('Focus Flow', Icons.lightbulb, Colors.amber, 5, 10.0, 741, 'binaural', 'ocean'),
    Preset('Anxiety Relief', Icons.self_improvement, Colors.green, 3, 6.0, 396, 'hybrid', 'forest'),
    Preset('Healing', Icons.favorite, Colors.purple, 4, 4.0, 528, 'hybrid', 'pink'),
    Preset('Meditation', Icons.self_improvement_outlined, Colors.deepPurple, 8, 4.0, 417, 'isochronic', 'ocean'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
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
          onTap: () => onPresetSelected(p),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [p.color, p.color.withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: p.color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(p.icon, size: 32, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  p.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}