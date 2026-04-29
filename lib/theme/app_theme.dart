import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────
  static const Color skyBlue = Color(0xFF2BA3EC);
  static const Color lightBlue = Color(0xFF4DB8FF);
  static const Color paleSky = Color(0xFFB3E0FF);
  static const Color iceBlue = Color(0xFFE8F6FF);
  static const Color background = Colors.white;

  // ── Accent Colors ─────────────────────────────────
  static const Color mintGreen = Color(0xFF00D4AA);
  static const Color softMint = Color(0xFFD0F5EE);
  static const Color amber = Color(0xFFFFB84D);
  static const Color softAmber = Color(0xFFFFF3DC);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color softCoral = Color(0xFFFFEEEE);

  // ── Neutrals ──────────────────────────────────────
  static const Color white = Colors.white;
  static const Color surfaceGrey = Color(0xFFF8FBFE);
  static const Color textDark = Color(0xFF0D2137);
  static const Color textMid = Color(0xFF4A6580);
  static const Color textLight = Color(0xFF8BAFC7);
  static const Color divider = Color(0xFFDEEDF8);

  // ── Gradients ─────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2BA3EC), Color(0xFF5BC8FF)],
  );

  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4AA), Color(0xFF4DE8C4)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F8FF)],
  );

  // ── Typography ────────────────────────────────────
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: textDark,
        letterSpacing: -0.5,
      );

  static TextStyle get headingMedium => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textDark,
      );

  static TextStyle get labelBold => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: textMid,
        letterSpacing: 0.5,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textMid,
      );

  // ── Card Shadow ───────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: skyBlue.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: skyBlue.withOpacity(0.18),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ];

  // ── Radius ────────────────────────────────────────
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
}