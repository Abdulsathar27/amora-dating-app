import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/animations/motion_widgets.dart';
import '../../../core/widgets/animations/press_scale.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../core/widgets/waveform.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/profile.dart';
import '../view_model/profile_setup_cubit.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// Shared layout for the six "Create your profile" steps.
class CreateStepScaffold extends StatelessWidget {
  const CreateStepScaffold({
    super.key,
    required this.step,
    required this.title,
    this.subtitle,
    required this.children,
    required this.onContinue,
    this.continueLabel = AppStrings.continueLabel,
    this.skip,
  });

  final int step;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onContinue;
  final String continueLabel;
  final VoidCallback? skip;

  @override
  Widget build(BuildContext context) {
    return LumeScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [StepProgress(step: step), AppGaps.h24, FadeRise(child: LumeTitle(title, subtitle: subtitle)), AppGaps.h24, ...children],
      ),
      bottom: [
        if (skip != null) LumeButton(AppStrings.skipForNow, variant: LumeButtonVariant.ghost, height: AppSizes.buttonHeightMd, onPressed: skip),
        LumeButton(continueLabel, onPressed: onContinue),
      ],
    );
  }
}

// ------------------------------------------------------------------ 1 Name
class CreateNameView extends StatelessWidget {
  const CreateNameView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
      builder:
          (context, s) => CreateStepScaffold(
            step: 1,
            title: AppStrings.nameTitle,
            onContinue: s.nameValid ? () => context.push(AppRoutes.createIdentity) : null,
            children: [
              LumeField(
                label: AppStrings.firstName,
                initialValue: s.name,
                onChanged: context.read<ProfileSetupCubit>().nameChanged,
                helper: AppStrings.firstNameHelper,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
    );
  }
}

// -------------------------------------------------------------- 2 Identity
class CreateIdentityView extends StatelessWidget {
  const CreateIdentityView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
      builder: (context, s) {
        final cubit = context.read<ProfileSetupCubit>();
        return CreateStepScaffold(
          step: 2,
          title: AppStrings.identityTitle,
          subtitle: AppStrings.identitySubtitle,
          onContinue: () => context.push(AppRoutes.createPhotos),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in Gender.values)
                  LumeTag(g.label, variant: s.gender == g ? TagVariant.selected : TagVariant.normal, onTap: () => cubit.genderSelected(g)),
              ],
            ),
            AppGaps.h24,
            Text(AppStrings.whoToMeet, style: LumeText.displayL),
            AppGaps.h24,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in InterestedIn.values)
                  LumeTag(i.label, variant: s.interestedIn == i ? TagVariant.selected : TagVariant.normal, onTap: () => cubit.interestedInSelected(i)),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------- 3 Photos
class CreatePhotosView extends StatelessWidget {
  const CreatePhotosView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
      builder: (context, s) {
        final cubit = context.read<ProfileSetupCubit>();
        Widget slot(int i, double w, double h, {bool arch = false}) {
          if (i < s.photos.length) {
            return GestureDetector(
              onLongPress: () => cubit.removePhoto(i),
              child: FadeRise(
                key: ValueKey(s.photos[i]),
                child:
                    arch
                        ? ArchPhoto(source: s.photos[i], width: w, height: h)
                        : ClipRRect(borderRadius: BorderRadius.circular(20), child: SizedBox(width: w, height: h, child: LumePhoto(s.photos[i]))),
              ),
            );
          }
          return PressScale(
            onTap: cubit.addPhoto,
            child: Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: arch ? AppRadius.arch(w) : BorderRadius.circular(20),
                border: Border.all(color: AppColors.lavender, width: 1.5),
              ),
              alignment: Alignment.center,
              child: const LumeIcon(LumeIcons.plus, size: 28),
            ),
          );
        }

        return CreateStepScaffold(
          step: 3,
          title: AppStrings.photosTitle,
          subtitle: AppStrings.photosSubtitle,
          onContinue: s.hasPhoto ? () => context.push(AppRoutes.createIntention) : null,
          children: [
            LayoutBuilder(
              builder: (_, box) {
                final big = box.maxWidth * 200 / 342;
                final small = box.maxWidth - big - 12;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    slot(0, big, 340, arch: true),
                    AppGaps.w12,
                    Column(children: [slot(1, small, 162), AppGaps.h12, slot(2, small, 166)]),
                  ],
                );
              },
            ),
            AppGaps.h20,
            const LumeNote(AppStrings.photosReviewedNote, icon: LumeIcons.shield),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------- 4 Intention
class CreateIntentionView extends StatelessWidget {
  const CreateIntentionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
      builder:
          (context, s) => CreateStepScaffold(
            step: 4,
            title: AppStrings.intentionTitle,
            subtitle: AppStrings.intentionSubtitle,
            onContinue: () => context.push(AppRoutes.createInterests),
            children: [
              StaggeredEntrance(
                spacing: 10,
                children: [
                  for (final i in RelationshipIntent.values)
                    IntentOption(intent: i, selected: s.intent == i, onTap: () => context.read<ProfileSetupCubit>().intentSelected(i)),
                ],
              ),
            ],
          ),
    );
  }
}

/// Selectable intention card: plum with a coral check when selected.
class IntentOption extends StatelessWidget {
  const IntentOption({super.key, required this.intent, required this.selected, required this.onTap});

  final RelationshipIntent intent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: PressScale(
        onTap: onTap,
        scale: 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.plum : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.plum : AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(intent.label, style: LumeText.titleS.copyWith(color: selected ? AppColors.surface : AppColors.ink)),
                    AppGaps.h2,
                    Text(intent.description, style: LumeText.bodyM.copyWith(color: selected ? AppColors.lavender : AppColors.muted)),
                  ],
                ),
              ),
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: const LumeIcon(LumeIcons.check, size: 22, color: AppColors.coral),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- 5 Interests
class CreateInterestsView extends StatelessWidget {
  const CreateInterestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
      builder:
          (context, s) => CreateStepScaffold(
            step: 5,
            title: AppStrings.interestsTitle,
            subtitle: AppStrings.pickUpToFive(s.interests.length),
            onContinue: s.interests.isNotEmpty ? () => context.push(AppRoutes.createVoice) : null,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final i in kInterestOptions)
                    LumeTag(
                      i,
                      variant: s.interests.contains(i) ? TagVariant.selected : TagVariant.normal,
                      onTap: () => context.read<ProfileSetupCubit>().interestToggled(i),
                    ),
                ],
              ),
            ],
          ),
    );
  }
}

// ----------------------------------------------------------------- 6 Voice
class CreateVoiceView extends StatelessWidget {
  const CreateVoiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
      builder:
          (context, s) => CreateStepScaffold(
            step: 6,
            title: AppStrings.voiceTitle,
            subtitle: AppStrings.voiceSubtitle,
            continueLabel: AppStrings.saveVoiceIntro,
            onContinue: s.hasVoice ? () => context.push(AppRoutes.verifySelfie) : null,
            skip: () => context.push(AppRoutes.verifySelfie),
            children: [VoiceRecorderCard(state: s, onToggle: context.read<ProfileSetupCubit>().toggleRecording)],
          ),
    );
  }
}

/// White recorder card: prompt, live waveform, timer, and a pulsing record button.
class VoiceRecorderCard extends StatelessWidget {
  const VoiceRecorderCard({super.key, required this.state, required this.onToggle});

  final ProfileSetupState state;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final progress = state.voiceSeconds / ProfileSetupState.maxVoice;
    final button = PressScale(
      onTap: onToggle,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle, boxShadow: LumeShadows.soft),
        alignment: Alignment.center,
        child: LumeIcon(state.isRecording ? LumeIcons.pause : LumeIcons.mic, size: 30, color: AppColors.ink),
      ),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(28), boxShadow: LumeShadows.card),
      child: Column(
        children: [
          Text(kVoicePrompt, textAlign: TextAlign.center, style: LumeText.quote),
          AppGaps.h18,
          Waveform(heights: Waveform.intro, progress: progress, playing: state.isRecording, duration: const Duration(seconds: 15)),
          AppGaps.h18,
          Text(state.voiceLabel, style: LumeText.labelM.copyWith(color: AppColors.muted)),
          AppGaps.h18,
          Semantics(
            button: true,
            label: state.isRecording ? AppStrings.stopRecording : AppStrings.recordVoiceIntro,
            child: state.isRecording ? Pulse(min: 1, max: 1.1, period: const Duration(milliseconds: 700), child: button) : button,
          ),
        ],
      ),
    );
  }
}
