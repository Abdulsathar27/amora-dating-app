import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lume_tokens.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      primary: AppColors.coral,
      secondary: AppColors.plum,
      surface: AppColors.surface,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: (LumeText.useGoogleFonts ? GoogleFonts.interTextTheme() : const TextTheme()).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.plum,
      ),
      inputDecorationTheme: const InputDecorationTheme(hoverColor: Colors.transparent, focusColor: Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.plum,
        selectionColor: AppColors.lavender,
        selectionHandleColor: AppColors.plum,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.plum,
        inactiveTrackColor: AppColors.line,
        thumbColor: AppColors.surface,
        trackHeight: 6,
        overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
        thumbShape: _RingThumb(),
        rangeThumbShape: _RingRangeThumb(),
        showValueIndicator: ShowValueIndicator.never,
      ),
    );
  }
}

/// White 24px handle with a 2px plum ring, as drawn in "Discovery filters".
class _RingThumb extends SliderComponentShape {
  const _RingThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size.square(24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    _paintRing(context.canvas, center);
  }
}

class _RingRangeThumb extends RangeSliderThumbShape {
  const _RingRangeThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size.square(24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    _paintRing(context.canvas, center);
  }
}

void _paintRing(Canvas canvas, Offset center) {
  canvas.drawCircle(center, 12, Paint()..color = AppColors.surface);
  canvas.drawCircle(
    center,
    11,
    Paint()
      ..color = AppColors.plum
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
}
