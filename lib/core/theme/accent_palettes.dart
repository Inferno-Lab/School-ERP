import 'package:flutter/material.dart';

enum AccentPreset {
  oceanBlue,
  emerald,
  royalPurple,
  sunsetOrange,
  rose,
  teal,
}

class AccentPalette {
  const AccentPalette({
    required this.preset,
    required this.nameKey,
    required this.seed,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final AccentPreset preset;
  final String nameKey;
  final Color seed;
  final Color gradientStart;
  final Color gradientEnd;

  static const all = <AccentPalette>[
    AccentPalette(
      preset: AccentPreset.oceanBlue,
      nameKey: 'accent.ocean',
      seed: Color(0xFF1D4ED8),
      gradientStart: Color(0xFF3B82F6),
      gradientEnd: Color(0xFF6366F1),
    ),
    AccentPalette(
      preset: AccentPreset.emerald,
      nameKey: 'accent.emerald',
      seed: Color(0xFF047857),
      gradientStart: Color(0xFF10B981),
      gradientEnd: Color(0xFF14B8A6),
    ),
    AccentPalette(
      preset: AccentPreset.royalPurple,
      nameKey: 'accent.purple',
      seed: Color(0xFF6D28D9),
      gradientStart: Color(0xFF8B5CF6),
      gradientEnd: Color(0xFFA78BFA),
    ),
    AccentPalette(
      preset: AccentPreset.sunsetOrange,
      nameKey: 'accent.sunset',
      seed: Color(0xFFC2410C),
      gradientStart: Color(0xFFFB923C),
      gradientEnd: Color(0xFFF43F5E),
    ),
    AccentPalette(
      preset: AccentPreset.rose,
      nameKey: 'accent.rose',
      seed: Color(0xFFBE123C),
      gradientStart: Color(0xFFFB7185),
      gradientEnd: Color(0xFFF472B6),
    ),
    AccentPalette(
      preset: AccentPreset.teal,
      nameKey: 'accent.teal',
      seed: Color(0xFF0F766E),
      gradientStart: Color(0xFF14B8A6),
      gradientEnd: Color(0xFF22D3EE),
    ),
  ];

  static AccentPalette byName(String name) {
    return all.firstWhere(
      (palette) => palette.preset.name == name,
      orElse: () => all.first,
    );
  }
}
