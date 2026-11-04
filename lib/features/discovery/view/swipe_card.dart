import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/profile.dart';
import '../view_model/discovery_bloc.dart';

/// Draggable profile card. Position comes from DiscoveryBloc, so the widget is stateless.
class SwipeCard extends StatelessWidget {
  const SwipeCard({
    super.key,
    required this.profile,
    required this.isTop,
    this.offset = Offset.zero,
    this.animate = true,
    this.photoIndex = 0,
    this.likeProgress = 0,
    this.superLikeProgress = 0,
    this.onDetails,
  });

  final Profile profile;
  final bool isTop;
  final Offset offset;
  final bool animate;
  final int photoIndex;
  final double likeProgress;
  final double superLikeProgress;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final angle = offset.dx / 1200 * math.pi / 2; // gentle tilt
    final card = _CardFace(
      profile: profile,
      photoIndex: isTop ? photoIndex : 0,
      likeProgress: likeProgress,
      superLikeProgress: superLikeProgress,
      onDetails: onDetails,
    );

    if (!isTop) {
      return Transform.scale(scale: 0.95, child: card);
    }

    final bloc = context.read<DiscoveryBloc>();
    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        onPanUpdate: (d) => bloc.add(CardDragUpdated(d.delta)),
        onPanEnd: (_) => bloc.add(const CardDragEnded()),
        onTapUp: (d) => bloc.add(PhotoTapped(forward: d.localPosition.dx > box.maxWidth / 2)),
        child: AnimatedContainer(
          duration: animate ? DiscoveryBloc.flyOutDuration : Duration.zero,
          curve: Curves.easeOut,
          transformAlignment: Alignment.bottomCenter,
          transform: Matrix4.translationValues(offset.dx, offset.dy, 0).multiplied(Matrix4.rotationZ(angle)),
          child: card,
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.profile,
    required this.photoIndex,
    required this.likeProgress,
    required this.superLikeProgress,
    this.onDetails,
  });

  final Profile profile;
  final int photoIndex;
  final double likeProgress;
  final double superLikeProgress;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final photos = profile.photos;
    final index = photos.isEmpty ? 0 : photoIndex.clamp(0, photos.length - 1);
    final prompt = profile.prompts.isEmpty ? null : profile.prompts.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: const BoxDecoration(boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black26)]),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkPhoto(photos.isEmpty ? null : photos[index]),
            // Photo progress bars
            if (photos.length > 1)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    for (var i = 0; i < photos.length; i++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i == index ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Bottom gradient + info
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1],
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: _CardInfo(profile: profile, prompt: index == 0 ? null : prompt, onDetails: onDetails),
            ),
            // Swipe stamps
            if (likeProgress > 0)
              _Stamp(label: 'LIKE', color: AppColors.like, opacity: likeProgress, alignment: Alignment.topLeft, angle: -0.35),
            if (likeProgress < 0)
              _Stamp(label: 'NOPE', color: AppColors.nope, opacity: -likeProgress, alignment: Alignment.topRight, angle: 0.35),
            if (superLikeProgress > 0 && likeProgress.abs() < 0.3)
              _Stamp(label: 'SUPER LIKE', color: AppColors.superLike, opacity: superLikeProgress, alignment: const Alignment(0, 0.4), angle: 0),
          ],
        ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.profile, this.prompt, this.onDetails});
  final Profile profile;
  final ProfilePrompt? prompt;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    const white = TextStyle(color: Colors.white);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                '${profile.name}  ${profile.age}',
                style: white.copyWith(fontSize: 30, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (profile.isVerified) const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 6),
              child: Icon(Icons.verified, color: AppColors.superLike, size: 24),
            ),
            const Spacer(),
            IconButton(
              onPressed: onDetails,
              icon: const Icon(Icons.info_outline, color: Colors.white, size: 28),
            ),
          ],
        ),
        _Chip(icon: Icons.favorite_border, text: profile.intent.label),
        const SizedBox(height: 6),
        if (prompt != null) ...[
          Text(prompt!.question, style: white.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(prompt!.answer, style: white.copyWith(fontSize: 18), maxLines: 3, overflow: TextOverflow.ellipsis),
        ] else ...[
          if (profile.jobTitle != null) _Line(Icons.work_outline, profile.jobTitle!),
          if (profile.distanceKm != null) _Line(Icons.location_on_outlined, '${profile.distanceKm!.toStringAsFixed(0)} km away'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final i in profile.interests.take(4)) _Chip(text: i)],
          ),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 15)),
        ]),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 4)],
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ]),
      );
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.color, required this.opacity, required this.alignment, required this.angle});
  final String label;
  final Color color;
  final double opacity;
  final Alignment alignment;
  final double angle;

  @override
  Widget build(BuildContext context) => Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: angle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label, style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ),
      );
}
