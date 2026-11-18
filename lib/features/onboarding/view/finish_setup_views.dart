import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/animations/motion_widgets.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../auth/view_model/auth_bloc.dart';
import '../view_model/profile_setup_cubit.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "Get verified" — selfie check with a sweeping scan ring.
class VerifySelfieView extends StatelessWidget {
  const VerifySelfieView({super.key});

  @override
  Widget build(BuildContext context) {
    final photo = context.select<ProfileSetupCubit, String?>((c) => c.state.photos.firstOrNull);
    return LumeScaffold(
      header: LumeHeader(title: AppStrings.getVerified, onBack: () => context.pop()),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppGaps.h20,
          Center(child: _ScanFrame(photo: photo)),
          AppGaps.h20,
          const FadeRise(child: LumeTitle(AppStrings.selfieTitle, subtitle: AppStrings.selfieSubtitle)),
        ],
      ),
      bottom: [
        LumeButton(
          AppStrings.skipForNow,
          variant: LumeButtonVariant.ghost,
          height: AppSizes.buttonHeightMd,
          onPressed: () => context.push(AppRoutes.locationPrivacy),
        ),
        LumeButton(
          AppStrings.takeSelfie,
          variant: LumeButtonVariant.plum,
          onPressed: () => context.push(AppRoutes.locationPrivacy),
        ),
      ],
    );
  }
}

class _ScanFrame extends StatefulWidget {
  const _ScanFrame({required this.photo});

  final String? photo;

  @override
  State<_ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<_ScanFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 350,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(135), child: LumePhoto(widget.photo)),
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(painter: _ScanPainter(_c.value, reduce: LumeMotion.reduceMotion(context))),
          ),
        ],
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  _ScanPainter(this.t, {required this.reduce});

  final double t;
  final bool reduce;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(135)).deflate(2);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppColors.coral.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    if (reduce) return;
    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(t * 2 * math.pi),
        colors: const [AppColors.coralTransparent, AppColors.coral, AppColors.coralTransparent],
        stops: const [0.0, 0.12, 0.25],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(rrect, sweep);
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.t != t;
}

/// "Nearby, but never exact." — fuzzy location with pulsing rings.
class LocationPrivacyView extends StatelessWidget {
  const LocationPrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
      builder: (context, s) => LumeScaffold(
        header: LumeHeader(onBack: () => context.pop()),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppGaps.h20,
            const FadeRise(child: LumeTitle(AppStrings.locationTitle, subtitle: AppStrings.locationSubtitle)),
            AppGaps.h20,
            const FuzzyMap(),
            AppGaps.h20,
            LumeCard(
              children: [
                LumeRow(
                  title: AppStrings.showApproxDistance,
                  subtitle: AppStrings.approxDistanceExample,
                  toggle: s.showDistance,
                  onToggle: context.read<ProfileSetupCubit>().showDistanceChanged,
                ),
              ],
            ),
          ],
        ),
        bottom: [LumeButton(AppStrings.allowLocation, onPressed: () => context.push(AppRoutes.profileReady))],
      ),
    );
  }
}

class FuzzyMap extends StatelessWidget {
  const FuzzyMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.lavenderSoft, borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Pulse(
            min: 0.92,
            max: 1.04,
            period: const Duration(milliseconds: 2200),
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lavender.withValues(alpha: 0.33)),
            ),
          ),
          Pulse(
            min: 0.9,
            max: 1.08,
            period: const Duration(milliseconds: 1600),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lavender.withValues(alpha: 0.53)),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.plum, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const LumeIcon(LumeIcons.pin, size: 22, color: AppColors.surface),
          ),
        ],
      ),
    );
  }
}

/// "You're ready, Maya." — saves the profile, then the router opens Discover.
class ProfileReadyView extends StatelessWidget {
  const ProfileReadyView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
      builder: (context, s) => LumeScaffold(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
        body: StaggeredEntrance(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ArchPhoto(source: s.photos.firstOrNull, width: 230, height: 300, shadow: LumeShadows.card),
            AppGaps.h20,
            LumeTitle(AppStrings.youreReady(s.name.trim()), subtitle: AppStrings.photosInReview, center: true),
            AppGaps.h20,
            const StatusChip(label: AppStrings.verified, icon: LumeIcons.verified),
            if (s.error != null) ...[AppGaps.h16, LumeNote(s.error!, danger: true)],
          ],
        ),
        bottom: [
          LumeButton(
            AppStrings.startDiscovering,
            loading: s.isSubmitting,
            onPressed: () async {
              final auth = context.read<AuthBloc>();
              if (await context.read<ProfileSetupCubit>().submit()) {
                auth.add(AuthOnboardingCompleted(name: s.name.trim()));
              }
            },
          ),
        ],
      ),
    );
  }
}
