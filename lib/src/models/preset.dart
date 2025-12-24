import 'package:flutter/material.dart';

class Preset {
  final String title;
  final IconData icon;
  final Color color;
  final double durationMin, beatFreq, carrierFreq;
  final String toneType, ambientType;

  const Preset(
    this.title,
    this.icon,
    this.color,
    this.durationMin,
    this.beatFreq,
    this.carrierFreq,
    this.toneType,
    this.ambientType,
  );
}