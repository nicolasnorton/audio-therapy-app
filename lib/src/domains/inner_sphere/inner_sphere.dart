import '../sphere_domain.dart';

class InnerSphere extends SphereDomain {
  const InnerSphere()
      : super(
          id: 'inner',
          displayName: 'Inner Sphere',
          description: 'ASMR, Binaural, Healing – Focused on internal resonance.',
        );

  @override
  String mapTextureToAsset(String texture) {
    switch (texture) {
      case 'dna_repair':
        return 'assets/sounds/inner/binaural_528.mp3';
      case 'deep_sleep':
        return 'assets/sounds/inner/ambient_default.mp3';
      case 'neural_mist': // Effectively a "brain bug repellent"
        return 'assets/sounds/inner/binaural_528.mp3';
      default:
        return 'assets/sounds/inner/ambient_default.mp3';
    }
  }

  @override
  List<String> get availableTextures => ['deep_sleep', 'dna_repair', 'neural_mist'];
}
