import 'package:flutter/material.dart';

abstract final class KalaColors {
  static const ink = Color(0xFF1A1720);
  static const warmPaper = Color(0xFFFFF4DD);
  static const terracotta = Color(0xFFE85D3F);
  static const turmeric = Color(0xFFFFC83D);
  static const indigo = Color(0xFF4C4BD5);
  static const leaf = Color(0xFF22715B);
  static const ivory = Color(0xFFFFFBF3);
}

abstract final class KalaTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: KalaColors.terracotta,
      brightness: Brightness.light,
      surface: KalaColors.ivory,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: KalaColors.warmPaper,
      fontFamily: 'sans-serif',
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
