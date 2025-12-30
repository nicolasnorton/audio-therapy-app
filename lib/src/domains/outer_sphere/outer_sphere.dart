import '../sphere_domain.dart';

class OuterSphere extends SphereDomain {
  const OuterSphere()
      : super(
          id: 'outer',
          displayName: 'Outer Sphere',
          description: 'Deterrents, Masking – Resonance against external interference.',
        );

  @override
  String mapTextureToAsset(String texture) {
    switch (texture) {
      case 'ultrasonic':
        return 'assets/sounds/outer/ultrasonic_18khz.mp3';
      default:
        return 'assets/sounds/outer/ultrasonic_18khz.mp3';
    }
  }

  @override
  List<String> get availableTextures => ['ultrasonic'];
}
