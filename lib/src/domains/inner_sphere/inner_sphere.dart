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
      case 'binaural_528':
        return 'assets/sounds/inner/binaural_528.mp3';
      case 'ambient_default':
      case 'default':
      default:
        return 'assets/sounds/inner/ambient_default.mp3';
    }
  }

  @override
  List<String> get availableTextures => ['default', 'binaural_528'];
}
