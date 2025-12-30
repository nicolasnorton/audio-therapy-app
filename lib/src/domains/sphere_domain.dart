abstract class SphereDomain {
  final String id;
  final String displayName;
  final String description;

  const SphereDomain({
    required this.id,
    required this.displayName,
    required this.description,
  });

  /// Maps a texture name to a valid asset path within this domain.
  String mapTextureToAsset(String texture);

  /// Returns a list of available textures for this domain.
  List<String> get availableTextures;
}
