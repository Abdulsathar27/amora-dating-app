import 'package:flutter/material.dart';

import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../core/widgets/waveform.dart';
import '../../../data/models/profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// Icon for each lifestyle key.
String lifestyleIcon(String key) => switch (key) {
  Lifestyle.sleep => LumeIcons.moon,
  Lifestyle.drinks => LumeIcons.wine,
  Lifestyle.diet => LumeIcons.leaf,
  Lifestyle.exercise => LumeIcons.run,
  Lifestyle.kids => LumeIcons.people,
  _ => LumeIcons.leaf,
};

/// "The postcard card": arched photo, voice chip, then a white note with the
/// name, distance, quote, tags and lifestyle. 358x560 in the design.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.profile,
    this.photoIndex = 0,
    this.onExpand,
    this.onPhotoTap,
    this.onVoiceTap,
    this.voicePlaying = false,
  });

  final Profile profile;
  final int photoIndex;
  final VoidCallback? onExpand;
  final ValueChanged<bool>? onPhotoTap;
  final VoidCallback? onVoiceTap;
  final bool voicePlaying;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final photos = p.photos;
    final index = photos.isEmpty ? 0 : photoIndex.clamp(0, photos.length - 1);
    return LayoutBuilder(
      builder: (_, box) {
        final w = box.maxWidth;
        final photoH = w * 362 / 358;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Photo arch
            GestureDetector(
              onTapUp: onPhotoTap == null ? null : (d) => onPhotoTap!(d.localPosition.dx > w / 2),
              child: Container(
                width: w,
                height: photoH,
                decoration: BoxDecoration(borderRadius: AppRadius.arch(w, bottom: 28), boxShadow: LumeShadows.card),
                child: ClipRRect(
                  borderRadius: AppRadius.arch(w, bottom: 28),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: LumePhoto(photos.isEmpty ? null : photos[index], key: ValueKey(index)),
                  ),
                ),
              ),
            ),
            if (photos.length > 1)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < photos.length; i++) ...[
                      if (i > 0) AppGaps.w6,
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: i == index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: i == index ? 1 : 0.47),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (p.voice != null)
              Positioned(
                left: 16,
                top: photoH - 118,
                child: VoiceChip(voice: p.voice!, playing: voicePlaying, onTap: onVoiceTap),
              ),
            if (p.compatibility != null)
              Positioned(
                right: 26,
                top: photoH - 106,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                  decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LumeIcon(LumeIcons.discover, size: 16),
                      AppGaps.w6,
                      Text(p.compatibility!, style: LumeText.caption.copyWith(color: AppColors.plum)),
                    ],
                  ),
                ),
              ),
            // Note
            Positioned(
              left: 12,
              right: 12,
              top: photoH - 56,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: LumeShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text('${p.name}, ${p.age}', style: LumeText.displayM, overflow: TextOverflow.ellipsis),
                        ),
                        if (p.isVerified) ...[
                          AppGaps.w6,
                          const LumeIcon(LumeIcons.verified, size: 22, color: AppColors.success),
                        ],
                        const Spacer(),
                        if (onExpand != null)
                          LumeIconButton(
                            LumeIcons.down,
                            onPressed: onExpand,
                            background: AppColors.lavenderSoft,
                            tooltip: AppStrings.viewFullProfile,
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        const LumeIcon(LumeIcons.pin, size: 16, color: AppColors.muted),
                        AppGaps.w5,
                        Text(p.distanceLabel, style: LumeText.bodyM),
                      ],
                    ),
                    if (p.quote != null) ...[
                      AppGaps.h7,
                      Text(
                        p.quote!,
                        style: LumeText.quote.copyWith(color: AppColors.ink),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    AppGaps.h7,
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        LumeTag(p.intent.tag, variant: TagVariant.blush),
                        for (final i in p.interests.take(2)) LumeTag(i, variant: TagVariant.lavender),
                      ],
                    ),
                    if (p.lifestyle.isNotEmpty) ...[
                      AppGaps.h7,
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          for (final e in p.lifestyle.entries.take(3))
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LumeIcon(lifestyleIcon(e.key), size: 16),
                                AppGaps.w4,
                                Text(e.value, style: LumeText.caption.copyWith(color: AppColors.ink)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// White pill with a coral play button and a mini waveform.
class VoiceChip extends StatelessWidget {
  const VoiceChip({super.key, required this.voice, this.playing = false, this.onTap});

  final VoiceIntro voice;
  final bool playing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? AppStrings.pauseVoiceIntro : AppStrings.playVoiceIntro,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: LumeShadows.soft,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: LumeIcon(playing ? LumeIcons.pause : LumeIcons.play, size: 16, color: AppColors.ink),
              ),
              AppGaps.w8,
              Waveform(
                heights: Waveform.chip,
                progress: 0.35,
                playing: playing,
                duration: Duration(seconds: voice.seconds),
              ),
              AppGaps.w8,
              Text(voice.durationLabel, style: LumeText.caption),
            ],
          ),
        ),
      ),
    );
  }
}
