import '../sphere_domain.dart';

class MiddleSphere extends SphereDomain {
  const MiddleSphere()
      : super(
          id: 'middle',
          displayName: 'Middle Sphere',
          description: 'Animal Calls, Textures – Resonance with the environment.',
        );

  @override
  String mapTextureToAsset(String texture) {
    switch (texture) {
      case 'purr':
        return 'assets/sounds/middle/cat_purr.mp3';
      default:
        return 'assets/sounds/middle/cat_purr.mp3'; // Fallback to purr for now
    }
  }

  @override
  List<String> get availableTextures => ['purr'];
}
