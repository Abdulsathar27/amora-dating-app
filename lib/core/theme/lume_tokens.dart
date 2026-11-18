import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Lumé design tokens: shadows, type scale and motion.
/// Colours live in `constants/app_colors.dart`, sizes in `constants/app_sizes.dart`.
class LumeShadows {
  LumeShadows._();
  static const soft = [BoxShadow(color: AppColors.shadowSoft, offset: Offset(0, 4), blurRadius: 16)];
  static const card = [BoxShadow(color: AppColors.shadowCard, offset: Offset(0, 12), blurRadius: 32)];
  static const float = [BoxShadow(color: AppColors.shadowFloat, offset: Offset(0, 18), blurRadius: 44)];
}

/// Type scale. Georgia is not available on Android/iOS by default, so the serif
/// uses Gelasio (metric-compatible with Georgia); the sans is Inter.
class LumeText {
  LumeText._();

  /// Widget tests turn this off so no font download is attempted.
  static bool useGoogleFonts = true;

  static TextStyle _serif(double size, double height, double spacing, {bool italic = false}) {
    final style = TextStyle(
      fontSize: size,
      height: height / size,
      letterSpacing: spacing,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: AppColors.plum,
    );
    return useGoogleFonts ? GoogleFonts.gelasio(textStyle: style) : style.copyWith(fontFamily: 'Gelasio');
  }

  static TextStyle _sans(double size, double height, FontWeight w, [double spacing = 0]) {
    final style = TextStyle(
      fontSize: size,
      height: height / size,
      fontWeight: w,
      letterSpacing: spacing,
      color: AppColors.ink,
    );
    return useGoogleFonts ? GoogleFonts.inter(textStyle: style) : style.copyWith(fontFamily: 'Inter');
  }

  static TextStyle get displayXL => _serif(42, 48, -0.5);
  static TextStyle get displayL => _serif(32, 38, -0.3);
  static TextStyle get displayM => _serif(26, 32, -0.2);
  static TextStyle get quote => _serif(20, 28, 0, italic: true);
  static TextStyle get wordmark => _serif(68, 76, 0, italic: true);

  static TextStyle get titleL => _sans(22, 28, FontWeight.w600, -0.2);
  static TextStyle get titleM => _sans(18, 24, FontWeight.w600, -0.1);
  static TextStyle get titleS => _sans(16, 22, FontWeight.w600);
  static TextStyle get bodyL => _sans(16, 24, FontWeight.w400).copyWith(color: AppColors.muted);
  static TextStyle get bodyM => _sans(14, 20, FontWeight.w400).copyWith(color: AppColors.muted);
  static TextStyle get labelL => _sans(16, 20, FontWeight.w600);
  static TextStyle get labelM => _sans(14, 18, FontWeight.w500);
  static TextStyle get caption => _sans(12, 16, FontWeight.w500).copyWith(color: AppColors.muted);
}

/// Motion spec from the "Motion" board of the design file.
class LumeMotion {
  LumeMotion._();

  /// Tap feedback: scale to 0.96, 120ms ease-out.
  static const tap = Duration(milliseconds: 120);
  static const tapScale = 0.96;

  /// Screen change: push 280ms ease-in-out; exits ~30% faster.
  static const push = Duration(milliseconds: 280);
  static const pushExit = Duration(milliseconds: 196);
  static const dissolve = Duration(milliseconds: 220);
  static const sheet = Duration(milliseconds: 300);

  /// Like heart: 1 → 1.25 → 1, bouncy, 320ms.
  static const likeHeart = Duration(milliseconds: 320);

  /// Match moment: arches slide in 480ms spring, heart pulses twice, particle bloom.
  static const match = Duration(milliseconds: 480);

  /// Card swipe: tilt up to 8°, flies off past 35% of the width.
  static const maxTiltDegrees = 8.0;
  static const swipeThreshold = 0.35;

  /// Reduced motion: springs become 150ms fades; particles and tilt off.
  static const reduced = Duration(milliseconds: 150);

  static const gentle = Curves.easeOutCubic;
  static const bouncy = Curves.elasticOut;

  static bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
