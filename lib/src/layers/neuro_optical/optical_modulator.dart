import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

class OpticalModulator extends StatefulWidget {
  final double frequencyHz;
  final double intensity;

  const OpticalModulator({
    super.key,
    required this.frequencyHz,
    required this.intensity,
  });

  @override
  State<OpticalModulator> createState() => _OpticalModulatorState();
}

class _OpticalModulatorState extends State<OpticalModulator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderBuilder(
      assetKey: 'lib/src/layers/neuro_optical/shaders/motion_aftereffect.frag',
      (context, shader, child) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // High frequency (e.g. 40Hz) -> faster movement
            // Low frequency (e.g. 2Hz) -> slower movement
            final speedMult = (widget.frequencyHz / 10.0).clamp(0.2, 5.0);
            shader.setFloat(0, _controller.value * 20.0 * 3.14159 * speedMult); 
            shader.setFloat(1, MediaQuery.of(context).size.width);
            shader.setFloat(2, MediaQuery.of(context).size.height);
            shader.setFloat(3, widget.intensity);
            shader.setFloat(4, widget.frequencyHz);
            
            return CustomPaint(
              painter: _ShaderPainter(shader),
              size: MediaQuery.of(context).size,
            );
          },
        );
      },
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final FragmentShader shader;

  _ShaderPainter(this.shader);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}