import 'package:flutter_test/flutter_test.dart';
import 'package:audio_therapy_app/src/domains/inner_sphere/inner_sphere.dart';
import 'package:audio_therapy_app/src/domains/middle_sphere/middle_sphere.dart';
import 'package:audio_therapy_app/src/domains/outer_sphere/outer_sphere.dart';

void main() {
  group('Sphere Domain Logic Tests', () {
    test('InnerSphere resolves textures correctly', () {
      const sphere = InnerSphere();
      expect(sphere.mapTextureToAsset('default'), 'assets/sounds/inner/ambient_default.mp3');
      expect(sphere.mapTextureToAsset('binaural_528'), 'assets/sounds/inner/binaural_528.mp3');
      expect(sphere.mapTextureToAsset('unknown'), 'assets/sounds/inner/ambient_default.mp3');
    });

    test('MiddleSphere resolves textures correctly', () {
      const sphere = MiddleSphere();
      expect(sphere.mapTextureToAsset('purr'), 'assets/sounds/middle/cat_purr.mp3');
      expect(sphere.mapTextureToAsset('unknown'), 'assets/sounds/middle/cat_purr.mp3');
    });

    test('OuterSphere resolves textures correctly', () {
      const sphere = OuterSphere();
      expect(sphere.mapTextureToAsset('ultrasonic'), 'assets/sounds/outer/ultrasonic_18khz.mp3');
      expect(sphere.mapTextureToAsset('unknown'), 'assets/sounds/outer/ultrasonic_18khz.mp3');
    });
  });
}
