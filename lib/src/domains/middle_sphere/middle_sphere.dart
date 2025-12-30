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
      case 'cat_zen':
        return 'assets/sounds/middle/cat_purr.mp3';
      case 'dog_whistle':
        return 'assets/sounds/middle/cat_purr.mp3'; // Placeholder
      case 'bio_harmony':
        return 'assets/sounds/middle/cat_purr.mp3';
      default:
        return 'assets/sounds/middle/cat_purr.mp3';
    }
  }

  @override
  List<String> get availableTextures => ['cat_zen', 'dog_whistle', 'bio_harmony'];
}
