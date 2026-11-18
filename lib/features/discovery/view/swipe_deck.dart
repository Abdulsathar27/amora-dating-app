import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/motion_widgets.dart';
import '../../../core/widgets/animations/press_scale.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../data/discovery_action.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/profile.dart';
import '../view_model/discovery_bloc.dart';
import 'compliment_sheet.dart';
import 'profile_card.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// The card stack + action buttons.
///
/// Motion spec: the card follows the finger and tilts up to 8°. Past 35% of the
/// width (or a fast fling) it flies off on a spring; otherwise it springs back.
/// A Like / Pass / Super Like stamp fades in with distance. All of it runs on
/// one AnimationController driven by SpringSimulation.
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({super.key, required this.top, this.next, required this.likes});

  final Profile top;
  final Profile? next;
  final int likes;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this)..addListener(_tick);

  Offset _offset = Offset.zero;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  Size _size = const Size(358, 560);
  bool _flying = false;
  int _photo = 0;
  bool _voicePlaying = false;

  static const _spring = SpringDescription(mass: 1, stiffness: 220, damping: 22);

  bool get _reduce => LumeMotion.reduceMotion(context);

  @override
  void didUpdateWidget(SwipeDeck old) {
    super.didUpdateWidget(old);
    if (old.top.id != widget.top.id) {
      _offset = Offset.zero;
      _photo = 0;
      _voicePlaying = false;
      _flying = false;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tick() => setState(() => _offset = Offset.lerp(_from, _to, _c.value)!);

  void _onPanUpdate(DragUpdateDetails d) {
    if (_flying) return;
    _c.stop();
    setState(() => _offset += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_flying) return;
    final v = d.velocity.pixelsPerSecond;
    final threshold = _size.width * LumeMotion.swipeThreshold;
    if (_offset.dx > threshold || v.dx > 900) {
      _fly(SwipeAction.like, velocity: v.dx.abs());
      return;
    }
    if (_offset.dx < -threshold || v.dx < -900) {
      _fly(SwipeAction.pass, velocity: v.dx.abs());
      return;
    }
    if (_offset.dy < -_size.height * 0.3 || v.dy < -1100) {
      _fly(SwipeAction.superLike, velocity: v.dy.abs());
      return;
    }
    _animateTo(Offset.zero, velocity: v.distance);
  }

  Future<void> _animateTo(Offset target, {double velocity = 0}) {
    _from = _offset;
    _to = target;
    final distance = (_to - _from).distance;
    if (_reduce) {
      _c.value = 0;
      return _c.animateTo(1, duration: LumeMotion.reduced);
    }
    final simulation = SpringSimulation(_spring, 0, 1, distance == 0 ? 0 : velocity / distance);
    return _c.animateWith(simulation);
  }

  /// Fly the top card off screen, then tell the ViewModel.
  Future<void> _fly(SwipeAction action, {double velocity = 0, String? comment}) async {
    if (_flying) return;
    _flying = true;
    if (action != SwipeAction.pass) HapticFeedback.mediumImpact();
    final w = MediaQuery.sizeOf(context).width;
    final exit = switch (action) {
      SwipeAction.like => Offset(w * 1.5, _offset.dy + 40),
      SwipeAction.pass => Offset(-w * 1.5, _offset.dy + 40),
      SwipeAction.superLike => Offset(_offset.dx, -MediaQuery.sizeOf(context).height),
    };
    await _animateTo(exit, velocity: math.max(velocity, 1200));
    if (!mounted) return;
    context.read<DiscoveryBloc>().add(CardSwiped(action, comment: comment));
  }

  Future<void> _compliment() async {
    final text = await showComplimentSheet(context, widget.top);
    if (text != null && mounted) _fly(SwipeAction.like, comment: text);
  }

  Future<void> _expand() async {
    final result = DiscoveryActionResult.from(
      await context.push<Object?>(AppRoutes.person, extra: FullProfileArgs(widget.top, fromDiscover: true)),
    );
    if (result != null && mounted) _fly(result.action, comment: result.comment);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (_, box) {
              // Keep the design's 358x560 proportion, shrinking on short screens.
              final w = math.min(box.maxWidth - 32, (box.maxHeight - 8) * 358 / 560);
              _size = Size(w, w * 560 / 358);
              final progress = (_offset.distance / (_size.width * LumeMotion.swipeThreshold)).clamp(0.0, 1.0);
              final likeT = (_offset.dx / (_size.width * LumeMotion.swipeThreshold)).clamp(-1.0, 1.0);
              final upT = (-_offset.dy / (_size.height * 0.3)).clamp(0.0, 1.0);
              final tilt = _reduce ? 0.0 : (likeT * LumeMotion.maxTiltDegrees) * math.pi / 180;

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  if (widget.next != null)
                    // Next card peek: rotated -5°, 55% opacity, settles as the top card leaves.
                    Positioned(
                      top: 17 * (1 - progress),
                      child: Opacity(
                        opacity: 0.55 + 0.45 * progress,
                        child: Transform.rotate(
                          angle: (-5 + 5 * progress) * math.pi / 180,
                          child: Transform.scale(
                            scale: 0.92 + 0.08 * progress,
                            child: SizedBox(
                              width: _size.width,
                              height: _size.height,
                              child:
                                  progress < 0.6
                                      ? Align(
                                        alignment: Alignment.topCenter,
                                        child: ArchPhoto(
                                          source: widget.next!.mainPhoto,
                                          width: _size.width * 330 / 358,
                                          height: _size.width * 340 / 358,
                                          bottomRadius: 28,
                                        ),
                                      )
                                      : ProfileCard(profile: widget.next!),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 0,
                    child: Transform.translate(
                      offset: _offset,
                      child: Transform.rotate(
                        angle: tilt,
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: SizedBox(
                            width: _size.width,
                            height: _size.height,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ProfileCard(
                                  profile: widget.top,
                                  photoIndex: _photo,
                                  voicePlaying: _voicePlaying,
                                  onVoiceTap: () => setState(() => _voicePlaying = !_voicePlaying),
                                  onExpand: _expand,
                                  onPhotoTap:
                                      (forward) => setState(() {
                                        _photo = (_photo + (forward ? 1 : -1)).clamp(
                                          0,
                                          math.max(0, widget.top.photos.length - 1),
                                        );
                                      }),
                                ),
                                if (likeT > 0.05)
                                  _Stamp(
                                    label: AppStrings.like,
                                    icon: LumeIcons.heart,
                                    color: AppColors.coral,
                                    opacity: likeT,
                                    angle: -12,
                                    left: 40,
                                  ),
                                if (likeT < -0.05)
                                  _Stamp(
                                    label: AppStrings.pass,
                                    icon: LumeIcons.close,
                                    color: AppColors.lavender,
                                    opacity: -likeT,
                                    angle: 12,
                                    right: 40,
                                  ),
                                if (upT > 0.05 && likeT.abs() < 0.3)
                                  _Stamp(
                                    label: AppStrings.superLike,
                                    icon: LumeIcons.star,
                                    color: AppColors.lavender,
                                    opacity: upT,
                                    angle: 0,
                                    center: true,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _ActionBar(
          likes: widget.likes,
          onPass: () => _fly(SwipeAction.pass),
          onCompliment: _compliment,
          onLike: () => _fly(SwipeAction.like),
          onSuperLike: () => _fly(SwipeAction.superLike),
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.icon,
    required this.color,
    required this.opacity,
    required this.angle,
    this.left,
    this.right,
    this.center = false,
  });

  final String label;
  final String icon;
  final Color color;
  final double opacity;
  final double angle;
  final double? left;
  final double? right;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final stamp = Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: Transform.scale(
          scale: 0.8 + 0.2 * opacity.clamp(0.0, 1.0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 18, 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: LumeShadows.soft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LumeIcon(icon, size: 24, color: AppColors.ink),
                AppGaps.w8,
                Text(label, style: LumeText.titleL),
              ],
            ),
          ),
        ),
      ),
    );
    if (center) return Positioned(left: 0, right: 0, top: 160, child: Center(child: stamp));
    return Positioned(top: 50, left: left, right: right, child: stamp);
  }
}

/// Pass · Compliment · Like · Super Like.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.likes,
    required this.onPass,
    required this.onCompliment,
    required this.onLike,
    required this.onSuperLike,
  });

  final int likes;
  final VoidCallback onPass;
  final VoidCallback onCompliment;
  final VoidCallback onLike;
  final VoidCallback onSuperLike;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DiscoveryActionButton(
            icon: LumeIcons.close,
            size: AppSizes.actionPass,
            iconSize: AppSizes.actionPassIcon,
            label: AppStrings.pass,
            onTap: onPass,
          ),
          AppGaps.w14,
          DiscoveryActionButton(
            icon: LumeIcons.compliment,
            size: AppSizes.actionSmall,
            iconSize: AppSizes.actionSmallIcon,
            label: AppStrings.sendACompliment,
            onTap: onCompliment,
          ),
          AppGaps.w14,
          HeartBounce(
            trigger: likes,
            child: DiscoveryActionButton(
              icon: LumeIcons.heart,
              size: AppSizes.actionLike,
              iconSize: AppSizes.actionLikeIcon,
              label: AppStrings.like,
              color: AppColors.coral,
              onTap: onLike,
            ),
          ),
          AppGaps.w14,
          DiscoveryActionButton(
            icon: LumeIcons.star,
            size: AppSizes.actionSmall,
            iconSize: AppSizes.actionSmallIcon,
            label: AppStrings.superLike,
            color: AppColors.lavender,
            onTap: onSuperLike,
          ),
        ],
      ),
    );
  }
}

/// Round action from "Discovery actions" on the Components page.
class DiscoveryActionButton extends StatelessWidget {
  const DiscoveryActionButton({
    super.key,
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.label,
    required this.onTap,
    this.color = AppColors.surface,
  });

  final String icon;
  final double size;
  final double iconSize;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final white = color == AppColors.surface;
    return Semantics(
      button: true,
      label: label,
      child: PressScale(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: white ? Border.all(color: AppColors.line) : null,
            boxShadow: LumeShadows.soft,
          ),
          alignment: Alignment.center,
          child: LumeIcon(icon, size: iconSize, color: white ? AppColors.plum : AppColors.ink),
        ),
      ),
    );
  }
}
