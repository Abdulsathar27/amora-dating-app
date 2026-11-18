import 'package:flutter/material.dart';

/// Every colour used in the app, taken 1:1 from the "Lumé tokens" collection
/// in the design file. Never write a `Color(0x…)` literal in a widget —
/// add it here and reference it by name.
class AppColors {
  AppColors._();

  // Brand
  static const coral = Color(0xFFFF647C);
  static const coralDeep = Color(0xFFC22E4E);
  static const plum = Color(0xFF572B50);
  static const lavender = Color(0xFFC9B6FF);
  static const lavenderSoft = Color(0xFFF0EAFF);
  static const blush = Color(0xFFFFE8EB);

  // Surfaces & text
  static const background = Color(0xFFFFF9F7);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF25212A);
  static const muted = Color(0xFF675F6C);
  static const line = Color(0xFFEFE5E2);

  // Status
  static const success = Color(0xFF1F7A58);
  static const successSoft = Color(0xFFDDF3E7);
  static const warning = Color(0xFF8F5A00);
  static const danger = Color(0xFFB8283F);
  static const dangerSoft = Color(0xFFFDE7EA);

  // Utility
  static const transparent = Color(0x00000000);
  static const coralTransparent = Color(0x00FF647C);
  static const shimmerClear = Color(0x00FFFFFF);
  static const shimmerHighlight = Color(0x66FFFFFF);

  // Shadow tints (plum at 8% / 14% / 20%)
  static const shadowSoft = Color(0x14572B50);
  static const shadowCard = Color(0x24572B50);
  static const shadowFloat = Color(0x33572B50);

  // "It's a Match" background
  static const matchTop = Color(0xFF6E3564);
  static const matchBottom = Color(0xFF3E1E3A);
  static const matchGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [matchTop, matchBottom],
  );
}
