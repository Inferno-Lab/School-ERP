import 'package:flutter/material.dart';

class SubjectColor {
  const SubjectColor({required this.tint, required this.tone});

  final Color tint;
  final Color tone;
}

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.glassFill,
    required this.glassBorder,
    required this.gradientStart,
    required this.gradientEnd,
    required this.shadow,
    required this.cardBorder,
    required this.subjects,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color glassFill;
  final Color glassBorder;
  final Color gradientStart;
  final Color gradientEnd;
  final Color shadow;
  final Color cardBorder;
  final Map<String, SubjectColor> subjects;

  SubjectColor subject(String id) =>
      subjects[id] ??
      const SubjectColor(tint: Color(0xFFEEF2F7), tone: Color(0xFF64748B));

  // ignore: sort_constructors_first
  factory AppColors.light({
    required Color gradientStart,
    required Color gradientEnd,
  }) {
    return AppColors(
      success: const Color(0xFF047857),
      onSuccess: Colors.white,
      successContainer: const Color(0xFFD1FAE5),
      warning: const Color(0xFFB45309),
      onWarning: Colors.white,
      warningContainer: const Color(0xFFFEF3C7),
      danger: const Color(0xFFBE123C),
      onDanger: Colors.white,
      dangerContainer: const Color(0xFFFFE4E6),
      info: const Color(0xFF1D4ED8),
      onInfo: Colors.white,
      infoContainer: const Color(0xFFDBEAFE),
      glassFill: const Color(0xB8FFFFFF),
      glassBorder: const Color(0x66FFFFFF),
      gradientStart: gradientStart,
      gradientEnd: gradientEnd,
      shadow: const Color(0x141C2434),
      cardBorder: const Color(0x00000000),
      subjects: _subjects(dark: false),
    );
  }

  // ignore: sort_constructors_first
  factory AppColors.dark({
    required Color gradientStart,
    required Color gradientEnd,
    bool amoled = false,
  }) {
    return AppColors(
      success: const Color(0xFF34D399),
      onSuccess: const Color(0xFF052E1F),
      successContainer: const Color(0xFF064E3B),
      warning: const Color(0xFFFBBF24),
      onWarning: const Color(0xFF3B2A05),
      warningContainer: const Color(0xFF78350F),
      danger: const Color(0xFFFB7185),
      onDanger: const Color(0xFF3F0714),
      dangerContainer: const Color(0xFF881337),
      info: const Color(0xFF93C5FD),
      onInfo: const Color(0xFF0B1B3A),
      infoContainer: const Color(0xFF1E3A8A),
      glassFill: const Color(0x14FFFFFF),
      glassBorder: const Color(0x22FFFFFF),
      gradientStart: gradientStart,
      gradientEnd: gradientEnd,
      shadow: const Color(0x66000000),
      cardBorder: amoled ? const Color(0xFF2A2A2A) : const Color(0x00000000),
      subjects: _subjects(dark: true),
    );
  }

  static Map<String, SubjectColor> _subjects({required bool dark}) {
    const tones = {
      'maths': Color(0xFF2563EB),
      'science': Color(0xFF059669),
      'english': Color(0xFF7C3AED),
      'hindi': Color(0xFFDB2777),
      'social': Color(0xFFEA580C),
      'computer': Color(0xFF0891B2),
      'art': Color(0xFFF97316),
      'pe': Color(0xFF16A34A),
      'music': Color(0xFFC026D3),
      'break': Color(0xFF64748B),
      'recess': Color(0xFF64748B),
    };
    const tints = {
      'maths': Color(0xFFE7F0FF),
      'science': Color(0xFFE5F8EF),
      'english': Color(0xFFF3E8FF),
      'hindi': Color(0xFFFFE8F1),
      'social': Color(0xFFFFF4E5),
      'computer': Color(0xFFE6F7FB),
      'art': Color(0xFFFFF0E8),
      'pe': Color(0xFFE9FBEA),
      'music': Color(0xFFFDE8F3),
      'break': Color(0xFFF1F5F9),
      'recess': Color(0xFFF1F5F9),
    };
    return {
      for (final entry in tones.entries)
        entry.key: SubjectColor(
          tone: entry.value,
          tint: dark
              ? entry.value.withValues(alpha: 0.18)
              : tints[entry.key]!,
        ),
    };
  }

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? glassFill,
    Color? glassBorder,
    Color? gradientStart,
    Color? gradientEnd,
    Color? shadow,
    Color? cardBorder,
    Map<String, SubjectColor>? subjects,
  }) {
    return AppColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      shadow: shadow ?? this.shadow,
      cardBorder: cardBorder ?? this.cardBorder,
      subjects: subjects ?? this.subjects,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      success: mix(success, other.success),
      onSuccess: mix(onSuccess, other.onSuccess),
      successContainer: mix(successContainer, other.successContainer),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      warningContainer: mix(warningContainer, other.warningContainer),
      danger: mix(danger, other.danger),
      onDanger: mix(onDanger, other.onDanger),
      dangerContainer: mix(dangerContainer, other.dangerContainer),
      info: mix(info, other.info),
      onInfo: mix(onInfo, other.onInfo),
      infoContainer: mix(infoContainer, other.infoContainer),
      glassFill: mix(glassFill, other.glassFill),
      glassBorder: mix(glassBorder, other.glassBorder),
      gradientStart: mix(gradientStart, other.gradientStart),
      gradientEnd: mix(gradientEnd, other.gradientEnd),
      shadow: mix(shadow, other.shadow),
      cardBorder: mix(cardBorder, other.cardBorder),
      subjects: t < 0.5 ? subjects : other.subjects,
    );
  }
}
