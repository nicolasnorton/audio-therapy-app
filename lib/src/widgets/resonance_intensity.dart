import 'package:flutter/material.dart';

class ResonanceIntensity extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const ResonanceIntensity({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: value,
      min: 0.0,
      max: 1.0,
      divisions: 100,
      label: 'Resonance Intensity: ${value.toStringAsFixed(2)}',
      onChanged: onChanged,
    );
  }
}