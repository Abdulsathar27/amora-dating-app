import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../data/models/profile.dart';
import '../view_model/profile_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "Your photos": drag to reorder, with moderation status per photo.
class ManagePhotosView extends StatelessWidget {
  const ManagePhotosView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, s) {
        final p = s.profile;
        if (p == null) return const SizedBox.shrink();
        final reviews = [
          for (var i = 0; i < p.photos.length; i++)
            i < p.photoReviews.length ? p.photoReviews[i] : PhotoReview.inReview,
        ];
        final rejected = reviews.contains(PhotoReview.rejected);
        return LumeScaffold(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          header: LumeHeader(title: AppStrings.yourPhotos, onBack: () => context.pop()),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.reorderHint, style: LumeText.bodyL),
              AppGaps.h16,
              LayoutBuilder(
                builder: (_, box) {
                  final w = (box.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 16,
                    children: [
                      for (var i = 0; i < p.photos.length; i++)
                        LongPressDraggable<int>(
                          data: i,
                          feedback: Opacity(
                            opacity: 0.85,
                            child: ArchPhoto(
                              source: p.photos[i],
                              width: w,
                              height: w * 210 / 173,
                              shadow: LumeShadows.float,
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _Slot(photo: p.photos[i], review: reviews[i], width: w),
                          ),
                          child: DragTarget<int>(
                            onAcceptWithDetails: (d) {
                              final photos = List<String>.of(p.photos);
                              final r = List<PhotoReview>.of(reviews);
                              photos.insert(i, photos.removeAt(d.data));
                              r.insert(i, r.removeAt(d.data));
                              context.read<ProfileBloc>().add(
                                ProfileSaved({'photos': photos, 'photo_reviews': r.map((e) => e.value).toList()}),
                              );
                            },
                            builder:
                                (_, candidates, _) => AnimatedScale(
                                  scale: candidates.isEmpty ? 1 : 1.04,
                                  duration: const Duration(milliseconds: 150),
                                  child: FadeRise(
                                    delay: Duration(milliseconds: 60 * i),
                                    child: _Slot(photo: p.photos[i], review: reviews[i], width: w),
                                  ),
                                ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (rejected) ...[AppGaps.h16, const LumeNote(AppStrings.photoRejectedNote, danger: true)],
            ],
          ),
        );
      },
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.photo, required this.review, required this.width});

  final String photo;
  final PhotoReview review;
  final double width;

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (review) {
      PhotoReview.approved => (LumeIcons.check, AppColors.success, AppColors.successSoft),
      PhotoReview.inReview => (LumeIcons.refresh, AppColors.plum, AppColors.lavenderSoft),
      PhotoReview.rejected => (LumeIcons.info, AppColors.danger, AppColors.dangerSoft),
    };
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArchPhoto(source: photo, width: width, height: width * 210 / 173),
          AppGaps.h8,
          StatusChip(label: review.label, icon: icon, color: color, background: bg),
        ],
      ),
    );
  }
}
