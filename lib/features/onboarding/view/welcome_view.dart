import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../core/widgets/value_cubit.dart';
import '../../../core/widgets/waveform.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// Welcome 1 · 2 · 3 — "Be known", "Voice", "Safety".
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  static const _pages = [
    (AppStrings.welcome1Title, AppStrings.welcome1Body),
    (AppStrings.welcome2Title, AppStrings.welcome2Body),
    (AppStrings.welcome3Title, AppStrings.welcome3Body),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ValueCubit<int>(0),
      child: Scaffold(
        body: SafeArea(
          child: _Pager(
            builder:
                (context, controller) => Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: controller,
                        itemCount: _pages.length,
                        onPageChanged: context.read<ValueCubit<int>>().set,
                        itemBuilder:
                            (_, i) =>
                                _WelcomePage(index: i, title: _pages[i].$1, body: _pages[i].$2, controller: controller),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: BlocBuilder<ValueCubit<int>, int>(
                        builder:
                            (context, page) => AnimatedSwitcher(
                              duration: LumeMotion.dissolve,
                              child: Column(
                                key: ValueKey(page == 0),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  LumeButton(
                                    switch (page) {
                                      0 => AppStrings.getStarted,
                                      1 => AppStrings.next,
                                      _ => AppStrings.continueLabel,
                                    },
                                    onPressed:
                                        () =>
                                            page < 2
                                                ? controller.nextPage(
                                                  duration: LumeMotion.push,
                                                  curve: Curves.easeInOut,
                                                )
                                                : context.push(AppRoutes.ageGate),
                                  ),
                                  if (page == 0) ...[
                                    AppGaps.h4,
                                    LumeButton(
                                      AppStrings.alreadyHaveAccount,
                                      variant: LumeButtonVariant.ghost,
                                      onPressed: () => context.push(AppRoutes.signIn),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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

/// Owns the PageController (the only state the pager needs).
class _Pager extends StatefulWidget {
  const _Pager({required this.builder});

  final Widget Function(BuildContext, PageController) builder;

  @override
  State<_Pager> createState() => _PagerState();
}

class _PagerState extends State<_Pager> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.index, required this.title, required this.body, required this.controller});

  final int index;
  final String title;
  final String body;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: index == 2 ? 360 : 340,
            width: double.infinity,
            child: switch (index) {
              0 => const _ArchesIllustration(),
              1 => const _VoicePreview(),
              _ => const _SafetyPromises(),
            },
          ),
          AppGaps.h24,
          FadeRise(child: LumeTitle(title, subtitle: body)),
          AppGaps.h24,
          _Dots(controller: controller, count: 3),
        ],
      ),
    );
  }
}

/// Pagination: the active dot stretches to 22px, following the PageController.
class _Dots extends StatelessWidget {
  const _Dots({required this.controller, required this.count});

  final PageController controller;
  final int count;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) {
      final page = controller.hasClients && controller.position.haveDimensions ? controller.page ?? 0 : 0.0;
      return Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) AppGaps.w6,
            Builder(
              builder: (_) {
                final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
                return Container(
                  width: 8 + 14 * t,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color.lerp(AppColors.line, AppColors.plum, t),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ],
        ],
      );
    },
  );
}

/// Welcome 1: three arches; the side ones slide out from behind Maya.
class _ArchesIllustration extends StatefulWidget {
  const _ArchesIllustration();

  @override
  State<_ArchesIllustration> createState() => _ArchesIllustrationState();
}

class _ArchesIllustrationState extends State<_ArchesIllustration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();
  late final _spread = CurvedAnimation(parent: _c, curve: const Interval(0.2, 1, curve: Curves.easeOutBack));
  late final _rise = CurvedAnimation(parent: _c, curve: const Interval(0, 0.6, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, box) {
        final w = math.min(box.maxWidth, 342.0);
        final dx = (w - 150) / 2;
        return AnimatedBuilder(
          animation: _c,
          builder:
              (_, _) => Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  for (final (photo, sign) in [('assets/images/leo.jpg', -1.0), ('assets/images/amara.jpg', 1.0)])
                    Positioned(
                      top: 90,
                      left: box.maxWidth / 2 - 75 + sign * dx * _spread.value,
                      child: Opacity(
                        opacity: _spread.value.clamp(0.0, 1.0),
                        child: ArchPhoto(source: photo, width: 150, height: 230),
                      ),
                    ),
                  Positioned(
                    top: 20 + 30 * (1 - _rise.value),
                    child: Opacity(
                      opacity: _rise.value,
                      child: const ArchPhoto(
                        source: 'assets/images/maya.jpg',
                        width: 190,
                        height: 300,
                        borderColor: AppColors.background,
                        borderWidth: 4,
                        shadow: LumeShadows.card,
                      ),
                    ),
                  ),
                ],
              ),
        );
      },
    );
  }
}

/// Welcome 2: Priya's voice card with a playing waveform.
class _VoicePreview extends StatelessWidget {
  const _VoicePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.plum, borderRadius: AppRadius.arch(330, bottom: 32)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const LumeAvatar('assets/images/priya.jpg', size: 112, ringColor: AppColors.coral),
          AppGaps.h16,
          Text(AppStrings.welcomeSampleName, style: LumeText.titleM.copyWith(color: AppColors.surface)),
          AppGaps.h16,
          Waveform(
            heights: Waveform.priya,
            playing: true,
            progress: 0.45,
            idleColor: AppColors.surface.withValues(alpha: 0.27),
            duration: const Duration(seconds: 6),
          ),
          AppGaps.h16,
          Text(
            AppStrings.welcomeSampleQuote,
            textAlign: TextAlign.center,
            style: LumeText.quote.copyWith(color: AppColors.lavender),
          ),
        ],
      ),
    );
  }
}

/// Welcome 3: the four safety promises.
class _SafetyPromises extends StatelessWidget {
  const _SafetyPromises();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (LumeIcons.verified, AppStrings.featureVerifiedTitle, AppStrings.featureVerifiedBody),
      (LumeIcons.pin, AppStrings.featureLocationTitle, AppStrings.featureLocationBody),
      (LumeIcons.compliment, AppStrings.featureConsentTitle, AppStrings.featureConsentBody),
      (LumeIcons.flag, AppStrings.featureHelpTitle, AppStrings.featureHelpBody),
    ];
    return LumeCard(
      children: [
        StaggeredEntrance(children: [for (final r in rows) LumeRow(icon: r.$1, title: r.$2, subtitle: r.$3)]),
      ],
    );
  }
}
