import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/resonance_state.dart';

class PresetService {
  static const String _key = 'aura_presets';

  Future<List<ResonanceState>> loadPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null) return [];
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ResonanceState.fromJson(json)).toList();
    } catch (e) {
      print('Error loading presets: $e');
      return [];
    }
  }

  Future<void> savePreset(ResonanceState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presets = await loadPresets();
      final updated = [...presets, state];
      final jsonList = updated.map((p) => p.toJson()).toList();
      await prefs.setString(_key, json.encode(jsonList));
    } catch (e) {
      print('Error saving preset: $e');
    }
  }
}