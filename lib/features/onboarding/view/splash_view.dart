import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/lume_components.dart';
import '../../auth/view_model/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// Splash: the arch glows in, Maya's photo rises from the ground line, then the
/// wordmark fades up. When the animation ends we route by auth state.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  Future<void> _continue(BuildContext context) async {
    final auth = context.read<AuthBloc>();
    final state = auth.state.status == AuthStatus.unknown ? await auth.stream.firstWhere((s) => s.status != AuthStatus.unknown) : auth.state;
    if (!context.mounted) return;
    context.go(switch (state.status) {
      AuthStatus.authenticated when state.needsOnboarding => AppRoutes.pledge,
      AuthStatus.authenticated => AppRoutes.discover,
      _ => AppRoutes.welcome,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(backgroundColor: AppColors.plum, body: Center(child: _SplashArt(onFinished: () => _continue(context)))),
    );
  }
}

class _SplashArt extends StatefulWidget {
  const _SplashArt({required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_SplashArt> createState() => _SplashArtState();
}

class _SplashArtState extends State<_SplashArt> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));

  late final _glow = CurvedAnimation(parent: _c, curve: const Interval(0, 0.35, curve: Curves.easeOut));
  late final _ground = CurvedAnimation(parent: _c, curve: const Interval(0.15, 0.45, curve: Curves.easeOutCubic));
  late final _photo = CurvedAnimation(parent: _c, curve: const Interval(0.25, 0.7, curve: Curves.easeOutBack));
  late final _word = CurvedAnimation(parent: _c, curve: const Interval(0.55, 0.85, curve: Curves.easeOut));
  late final _tag = CurvedAnimation(parent: _c, curve: const Interval(0.7, 1, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) Future<void>.delayed(const Duration(milliseconds: 250), widget.onFinished);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (LumeMotion.reduceMotion(context)) _c.duration = const Duration(milliseconds: 600);
    return AnimatedBuilder(
      animation: _c,
      builder:
          (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 260,
                height: 324,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Arch glow outline
                    Opacity(
                      opacity: _glow.value,
                      child: Transform.scale(
                        scale: 0.92 + 0.08 * _glow.value,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 260,
                          height: 322,
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.arch(260, bottom: 0),
                            border: Border.all(color: AppColors.coral, width: 1.5),
                            boxShadow: [BoxShadow(color: AppColors.coral.withValues(alpha: 0.25 * _glow.value), blurRadius: 40)],
                          ),
                        ),
                      ),
                    ),
                    // Photo rising out of the ground
                    Positioned(
                      left: 20,
                      top: 22,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          heightFactor: _photo.value.clamp(0.0, 1.0),
                          child: const ArchPhoto(source: 'assets/images/maya.jpg', width: 220, height: 300, bottomRadius: 0),
                        ),
                      ),
                    ),
                    // Ground line
                    Positioned(left: 130 - 130 * _ground.value, top: 321, child: Container(width: 260 * _ground.value, height: 3, color: AppColors.coral)),
                  ],
                ),
              ),
              AppGaps.h38,
              Opacity(
                opacity: _word.value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - _word.value)),
                  child: Text(AppStrings.wordmark, style: LumeText.wordmark.copyWith(color: AppColors.surface)),
                ),
              ),
              AppGaps.h6,
              Opacity(opacity: _tag.value, child: Text(AppStrings.tagline, style: LumeText.quote.copyWith(color: AppColors.lavender))),
            ],
          ),
    );
  }
}
