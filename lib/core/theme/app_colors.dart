import 'package:flutter/material.dart';

/// Edstream Brand Color Tokens
/// Mirroring the exact values defined in the dashboard's Tailwind configuration.
abstract class AppColors {
  // Brand Foundation
  static const Color primary = Color(0xFF0012BF); // Royal Blue
  static const Color secondary = Color(0xFF4D44B5); // Signature Indigo/Purple
  static const Color dark = Color(0xFF131129); // Deep Midnight Charcoal / Body
  static const Color light = Color(0xFF303972); // Slate Navy / Headings
  static const Color background = Color(0xFFF3F4FF); // Soft Lavender Ice Scaffold
  static const Color surface = Color(0xFFFFFFFF); // Pure White Cards / Sheets
  static const Color darker = Color(0xFF171717);

  // Status & Feedback
  static const Color success = Color(0xFF22C55E); // Green
  static const Color danger = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFFACC15); // Yellow/Amber
  static const Color info = Color(0xFF3B82F6); // Blue

  // Custom Neutral & Accent Tints
  static const Color color1Light = Color(0xFFC1BBEB); // Soft Lavender Accent / Tag
  static const Color color2Light = Color(0xFFA098AE); // Muted Grey / Subtitles
  static const Color color3Light = Color(0xFFEFF0F6); // Input Fill / Neutral Tint
  static const Color color4Light = Color(0xFFA9ACB4); // Border / Placeholder
  static const Color color5Light = Color(0xFF292D32); // Neutral Dark / Icons
  static const Color color6Light = Color(0x80000000); // Overlay (50% Black)
  static const Color color7Light = Color(0xFF334155); // Slate Dark

  // Role Accents
  static const Color teacherAccent = Color(0xFF4D44B5);
  static const Color studentAccent = Color(0xFF0012BF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF0012BF), Color(0xFF4D44B5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bannerGradient = LinearGradient(
    colors: [Color(0xFF4D44B5), Color(0xFF7568EA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Box Shadows (Mirroring Tailwind shadow system)
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowBase = [
    BoxShadow(
      color: Color(0x1A000000), // rgba(0, 0, 0, 0.1)
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A000000), // rgba(0, 0, 0, 0.1)
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x12303972), // subtle slate navy shadow
      blurRadius: 14,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> shadow3xl = [
    BoxShadow(
      color: Color(0x26928787), // rgba(146, 135, 135, 0.15)
      blurRadius: 8,
      offset: Offset(0, 0),
    ),
  ];
}
