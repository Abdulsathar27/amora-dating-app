import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../core/widgets/waveform.dart';
import '../../../data/discovery_action.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/profile.dart';
import '../../safety/view/safety_views.dart';
import 'compliment_sheet.dart';
import 'profile_card.dart';
import 'swipe_deck.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "Full profile": everything someone shared, plus starters and safety links.
/// Opened from Discover, it pops with the chosen [SwipeAction].
class FullProfileView extends StatelessWidget {
  const FullProfileView({super.key, required this.profile, this.fromDiscover = false});

  final Profile profile;
  final bool fromDiscover;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, fromDiscover ? 140 : 40),
              children: [
                Row(
                  children: [
                    LumeIconButton(LumeIcons.down, tooltip: AppStrings.close, background: AppColors.surface, bordered: true, onPressed: () => context.pop()),
                    const Spacer(),
                    LumeIconButton(
                      LumeIcons.more,
                      tooltip: AppStrings.safetyOptions,
                      background: AppColors.surface,
                      bordered: true,
                      onPressed: () => showProfileSafetySheet(context, p),
                    ),
                  ],
                ),
                AppGaps.h20,
                FadeRise(
                  child: AspectRatio(
                    aspectRatio: 358 / 440,
                    child: LayoutBuilder(builder: (_, b) => ArchPhoto(source: p.mainPhoto, width: b.maxWidth, height: b.maxHeight, shadow: LumeShadows.card)),
                  ),
                ),
                AppGaps.h20,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('${p.name}, ${p.age}', style: LumeText.displayL),
                          if (p.isVerified) const StatusChip(label: AppStrings.verified, icon: LumeIcons.verified),
                        ],
                      ),
                      AppGaps.h6,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(padding: EdgeInsets.only(top: 2), child: LumeIcon(LumeIcons.pin, size: 16, color: AppColors.muted)),
                          AppGaps.w5,
                          Expanded(child: Text(AppStrings.locationHidden(p.distanceLabel), style: LumeText.bodyM)),
                        ],
                      ),
                      if (p.bio.isNotEmpty) ...[AppGaps.h6, Text(p.bio, style: LumeText.bodyL.copyWith(color: AppColors.ink))],
                    ],
                  ),
                ),
                if (p.voice != null || p.videoThumb != null) ...[
                  AppGaps.h20,
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        if (p.videoThumb != null) ...[
                          Expanded(
                            flex: 157,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  LumePhoto(p.videoThumb),
                                  Center(
                                    child: LumeIconButton(
                                      LumeIcons.play,
                                      size: 56,
                                      iconSize: 24,
                                      color: AppColors.ink,
                                      background: AppColors.surface,
                                      tooltip: AppStrings.playVideoIntro,
                                      onPressed: () => showLumeSnack(context, AppStrings.videoComingSoon),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AppGaps.w12,
                        ],
                        if (p.voice != null)
                          Expanded(
                            flex: 189,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.plum, borderRadius: BorderRadius.circular(24)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppStrings.voiceIntro, style: LumeText.labelM.copyWith(color: AppColors.lavender)),
                                  const Spacer(),
                                  Text(p.voice!.prompt, style: LumeText.quote.copyWith(color: AppColors.surface), maxLines: 3, overflow: TextOverflow.ellipsis),
                                  const Spacer(),
                                  Waveform(
                                    heights: Waveform.chip.followedBy(Waveform.chip.take(6)).toList(),
                                    playing: true,
                                    progress: 0.3,
                                    idleColor: AppColors.surface.withValues(alpha: 0.3),
                                    duration: Duration(seconds: p.voice!.seconds),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                for (final prompt in p.prompts) ...[AppGaps.h20, PromptCard(prompt: prompt)],
                if (p.photos.length > 1) ...[
                  AppGaps.h20,
                  ClipRRect(borderRadius: BorderRadius.circular(28), child: AspectRatio(aspectRatio: 358 / 320, child: LumePhoto(p.photos[1]))),
                ],
                if (p.personality.isNotEmpty) ...[AppGaps.h20, _Personality(traits: p.personality)],
                if (p.activities.isNotEmpty) ...[
                  AppGaps.h20,
                  _TagSection(title: AppStrings.favouriteActivities, tags: p.activities, variant: TagVariant.lavender),
                ],
                if (p.onRepeat.isNotEmpty) ...[AppGaps.h20, _OnRepeat(songs: p.onRepeat)],
                if (p.interests.isNotEmpty) ...[AppGaps.h20, _TagSection(title: AppStrings.hobbiesAndInterests, tags: p.interests)],
                if (p.relationshipGoal != null) ...[
                  AppGaps.h20,
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.relationshipGoals, style: LumeText.labelM.copyWith(color: AppColors.coralDeep)),
                        AppGaps.h8,
                        Text(p.relationshipGoal!, style: LumeText.quote),
                      ],
                    ),
                  ),
                ],
                if (p.lifestyle.isNotEmpty) ...[
                  AppGaps.h20,
                  LumeCard(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final e in p.lifestyle.entries) LumeRow(icon: lifestyleIcon(e.key), title: Lifestyle.labels[e.key] ?? e.key, value: e.value),
                    ],
                  ),
                ],
                if (p.starters.isNotEmpty) ...[
                  AppGaps.h20,
                  Text(AppStrings.conversationStarters, style: LumeText.titleS.copyWith(color: AppColors.plum)),
                  AppGaps.h10,
                  for (final s in p.starters) ...[StarterChip(text: s, onTap: fromDiscover ? () => context.pop(SwipeAction.like) : null), AppGaps.h10],
                ],
                AppGaps.h10,
                Row(
                  children: [
                    Expanded(child: LumeButton(AppStrings.blockName(p.name), variant: LumeButtonVariant.ghost, onPressed: () => showBlockSheet(context, p))),
                    AppGaps.w8,
                    Expanded(
                      child: LumeButton(
                        AppStrings.report,
                        variant: LumeButtonVariant.danger,
                        onPressed: () => context.push(AppRoutes.reportReason(p.id, p.name)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (fromDiscover)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + MediaQuery.paddingOf(context).bottom),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: LumeShadows.float,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DiscoveryActionButton(
                      icon: LumeIcons.close,
                      size: AppSizes.actionPass,
                      iconSize: AppSizes.actionPassIcon,
                      label: AppStrings.pass,
                      onTap: () => context.pop(SwipeAction.pass),
                    ),
                    AppGaps.w14,
                    DiscoveryActionButton(
                      icon: LumeIcons.compliment,
                      size: AppSizes.actionSmall,
                      iconSize: AppSizes.actionSmallIcon,
                      label: AppStrings.sendACompliment,
                      onTap: () async {
                        final text = await showComplimentSheet(context, p);
                        if (text != null && context.mounted) context.pop(DiscoveryActionResult(SwipeAction.like, comment: text));
                      },
                    ),
                    AppGaps.w14,
                    DiscoveryActionButton(
                      icon: LumeIcons.heart,
                      size: AppSizes.actionLike,
                      iconSize: AppSizes.actionLikeIcon,
                      label: AppStrings.like,
                      color: AppColors.coral,
                      onTap: () => context.pop(SwipeAction.like),
                    ),
                    AppGaps.w14,
                    DiscoveryActionButton(
                      icon: LumeIcons.star,
                      size: AppSizes.actionSmall,
                      iconSize: AppSizes.actionSmallIcon,
                      label: AppStrings.superLike,
                      color: AppColors.lavender,
                      onTap: () => context.pop(SwipeAction.superLike),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Card/Prompt: muted question + serif italic answer.
class PromptCard extends StatelessWidget {
  const PromptCard({super.key, required this.prompt});

  final ProfilePrompt prompt;

  @override
  Widget build(BuildContext context) => LumeCard(
    padding: const EdgeInsets.all(20),
    children: [Text(prompt.question, style: LumeText.labelM.copyWith(color: AppColors.muted)), AppGaps.h10, Text(prompt.answer, style: LumeText.quote)],
  );
}

/// Lavender conversation-starter row with a send icon.
class StarterChip extends StatelessWidget {
  const StarterChip({super.key, required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.lavenderSoft, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Expanded(child: Text(text, style: LumeText.labelM.copyWith(color: AppColors.plum))),
            AppGaps.w10,
            const LumeIcon(LumeIcons.send, size: 20),
          ],
        ),
      ),
    ),
  );
}

class _TagSection extends StatelessWidget {
  const _TagSection({required this.title, required this.tags, this.variant = TagVariant.normal});

  final String title;
  final List<String> tags;
  final TagVariant variant;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: LumeText.titleS.copyWith(color: AppColors.plum)),
        AppGaps.h10,
        Wrap(spacing: 8, runSpacing: 8, children: [for (final t in tags) LumeTag(t, variant: variant)]),
      ],
    ),
  );
}

class _Personality extends StatelessWidget {
  const _Personality({required this.traits});

  final List<PersonalityTrait> traits;

  @override
  Widget build(BuildContext context) => LumeCard(
    padding: const EdgeInsets.all(20),
    children: [
      Text(AppStrings.personality, style: LumeText.titleS.copyWith(color: AppColors.plum)),
      for (final t in traits) ...[
        AppGaps.h12,
        Row(children: [Text(t.left, style: LumeText.caption), const Spacer(), Text(t.right, style: LumeText.caption)]),
        AppGaps.h6,
        LayoutBuilder(
          builder:
              (_, b) => SizedBox(
                height: 16,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(height: 8, decoration: BoxDecoration(color: AppColors.lavenderSoft, borderRadius: BorderRadius.circular(4))),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.5, end: t.value),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutBack,
                      builder: (_, v, _) => Positioned(left: (b.maxWidth - 16) * v, child: const CircleAvatar(radius: 8, backgroundColor: AppColors.plum)),
                    ),
                  ],
                ),
              ),
        ),
      ],
    ],
  );
}

class _OnRepeat extends StatelessWidget {
  const _OnRepeat({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) => LumeCard(
    padding: const EdgeInsets.all(16),
    children: [
      Row(children: [const LumeIcon(LumeIcons.music, size: 20), AppGaps.w8, Text(AppStrings.onRepeat, style: LumeText.titleS.copyWith(color: AppColors.plum))]),
      for (final s in songs) ...[
        AppGaps.h10,
        Row(
          children: [
            const LumeIconButton(LumeIcons.play, onPressed: null, iconSize: 18, background: AppColors.lavenderSoft, color: AppColors.ink),
            AppGaps.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(s.title, style: LumeText.labelM), Text(s.note, style: LumeText.caption)],
              ),
            ),
          ],
        ),
      ],
    ],
  );
}
