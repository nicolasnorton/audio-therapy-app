class ResonanceState {
  final String name;
  final double frequencyHz;
  final String sphereType;
  final double intensity;
  final String texture;
  final String toneType;
  final double carrierFreq;

  ResonanceState({
    this.name = 'Untitled',
    required this.frequencyHz,
    required this.sphereType,
    this.intensity = 1.0,
    this.texture = 'default',
    this.toneType = 'hybrid',
    this.carrierFreq = 528.0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'frequencyHz': frequencyHz,
        'sphereType': sphereType,
        'intensity': intensity,
        'texture': texture,
        'toneType': toneType,
        'carrierFreq': carrierFreq,
      };

  factory ResonanceState.fromJson(Map<String, dynamic> json) => ResonanceState(
        name: json['name'],
        frequencyHz: json['frequencyHz'],
        sphereType: json['sphereType'],
        intensity: json['intensity'],
        texture: json['texture'],
        toneType: json['toneType'],
        carrierFreq: json['carrierFreq'],
      );
}