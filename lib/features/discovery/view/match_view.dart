import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../data/models/match.dart';
import '../../profile/view_model/profile_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "It's a Match!" — the match moment.
///
/// Motion spec: arches slide in and overlap (480ms spring), the heart pulses
/// twice, then a soft particle bloom. One AnimationController sequences it all.
class MatchView extends StatelessWidget {
  const MatchView({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final myPhoto = context.select<ProfileBloc, String?>((b) => b.state.profile?.mainPhoto);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.matchGradient),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _MatchMoment(
                    myPhoto: myPhoto ?? 'assets/images/maya.jpg',
                    theirPhoto: match.profile.mainPhoto,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.itsAMatch,
                        style: LumeText.wordmark.copyWith(fontSize: 52, height: 60 / 52, color: AppColors.surface),
                      ),
                      AppGaps.h10,
                      Text(
                        AppStrings.matchBody(match.profile.name),
                        textAlign: TextAlign.center,
                        style: LumeText.bodyL.copyWith(color: AppColors.lavender),
                      ),
                    ],
                  ),
                ),
                AppGaps.h40,
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    children: [
                      LumeButton(
                        AppStrings.startConversation,
                        onPressed: () => context.pushReplacement(AppRoutes.chat(match.id), extra: match),
                      ),
                      AppGaps.h6,
                      LumeButton(
                        AppStrings.continueDiscovering,
                        variant: LumeButtonVariant.ghost,
                        ghostColor: AppColors.surface,
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchMoment extends StatefulWidget {
  const _MatchMoment({required this.myPhoto, required this.theirPhoto});

  final String myPhoto;
  final String? theirPhoto;

  @override
  State<_MatchMoment> createState() => _MatchMomentState();
}

class _MatchMomentState extends State<_MatchMoment> with SingleTickerProviderStateMixin {
  // 0–0.24: arches slide in (≈480ms of 2000ms). 0.24–0.62: two heart pulses. 0.5–1: particle bloom.
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

  late final _arches = CurvedAnimation(parent: _c, curve: const Interval(0, 0.24, curve: Curves.easeOutBack));
  late final _heartIn = CurvedAnimation(parent: _c, curve: const Interval(0.16, 0.3, curve: Curves.elasticOut));
  late final _pulse = TweenSequence([
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18).chain(CurveTween(curve: Curves.easeOut)), weight: 8),
    TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 8),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18).chain(CurveTween(curve: Curves.easeOut)), weight: 8),
    TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 8),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 38),
  ]).animate(_c);
  late final _bloom = CurvedAnimation(parent: _c, curve: const Interval(0.5, 1, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = LumeMotion.reduceMotion(context);
    if (reduce) _c.duration = LumeMotion.reduced;
    return LayoutBuilder(
      builder: (_, box) {
        final cx = box.maxWidth / 2;
        final cy = box.maxHeight / 2;
        return AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final a = _arches.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Ambient sparks from the design.
                for (final (x, y, r, c) in const [
                  (0.11, 0.08, 4.0, AppColors.coral),
                  (0.85, 0.03, 5.0, AppColors.lavender),
                  (0.16, 0.72, 3.0, AppColors.lavender),
                  (0.88, 0.70, 3.5, AppColors.coral),
                  (0.07, 0.40, 2.5, AppColors.background),
                  (0.93, 0.37, 3.0, AppColors.background),
                  (0.49, 0.01, 3.0, AppColors.coral),
                ])
                  Positioned(
                    left: box.maxWidth * x,
                    top: box.maxHeight * y,
                    child: Opacity(opacity: a.clamp(0, 1), child: CircleAvatar(radius: r, backgroundColor: c)),
                  ),
                if (!reduce)
                  Positioned.fill(child: CustomPaint(painter: _BloomPainter(_bloom.value, Offset(cx, cy + 40)))),
                // Arches slide in from either side and overlap, tilted ±6°.
                Positioned(
                  left: cx - 168 - (1 - a) * 220,
                  top: cy - 135,
                  child: Transform.rotate(
                    angle: -6 * math.pi / 180,
                    child: ArchPhoto(
                      source: widget.myPhoto,
                      width: 180,
                      height: 270,
                      borderColor: AppColors.surface,
                      borderWidth: 4,
                      shadow: LumeShadows.float,
                    ),
                  ),
                ),
                Positioned(
                  left: cx - 1 + (1 - a) * 220,
                  top: cy - 124,
                  child: Transform.rotate(
                    angle: 6 * math.pi / 180,
                    child: ArchPhoto(
                      source: widget.theirPhoto,
                      width: 180,
                      height: 270,
                      borderColor: AppColors.surface,
                      borderWidth: 4,
                      shadow: LumeShadows.float,
                    ),
                  ),
                ),
                // Heart with halo.
                Positioned(
                  left: cx - 54,
                  top: cy + 12,
                  child: Transform.scale(
                    scale: _heartIn.value * _pulse.value,
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.coral.withValues(alpha: 0.27)),
                      alignment: Alignment.center,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const LumeIcon(LumeIcons.heart, size: 40, color: AppColors.ink),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Soft particle bloom: coral, lavender and blush dots drift outward and fade.
class _BloomPainter extends CustomPainter {
  _BloomPainter(this.t, this.center);

  final double t;
  final Offset center;

  static final _particles = List.generate(28, (i) {
    final r = math.Random(i * 7919);
    return (r.nextDouble() * 2 * math.pi, 80 + r.nextDouble() * 140, 2 + r.nextDouble() * 4, i % 3);
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    const colors = [AppColors.coral, AppColors.lavender, AppColors.blush];
    for (final (angle, dist, radius, c) in _particles) {
      final d = dist * t;
      final p = center + Offset(math.cos(angle) * d, math.sin(angle) * d);
      canvas.drawCircle(p, radius * (1 - t * 0.5), Paint()..color = colors[c].withValues(alpha: (1 - t) * 0.9));
    }
  }

  @override
  bool shouldRepaint(_BloomPainter old) => old.t != t;
}
