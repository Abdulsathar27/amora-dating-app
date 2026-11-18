import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/animations/motion_widgets.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../core/widgets/value_cubit.dart';
import '../../../core/widgets/waveform.dart';
import '../../onboarding/view_model/profile_setup_cubit.dart' show kVoicePrompt;
import '../view_model/profile_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "Voice intro": play, re-record or remove.
class VoiceIntroView extends StatelessWidget {
  const VoiceIntroView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ValueCubit<bool>(false), // playing
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, s) {
          final p = s.profile;
          final voice = p?.voice;
          return LumeScaffold(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            header: LumeHeader(title: AppStrings.voiceIntro, onBack: () => context.pop()),
            body: StaggeredEntrance(
              spacing: 16,
              children: [
                BlocBuilder<ValueCubit<bool>, bool>(
                  builder:
                      (context, playing) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: AppColors.plum, borderRadius: AppRadius.arch(358, bottom: 32)),
                        child: Column(
                          children: [
                            AppGaps.h7,
                            LumeAvatar(p?.mainPhoto, size: 104, ringColor: AppColors.coral),
                            AppGaps.h16,
                            Text(voice?.prompt ?? kVoicePrompt, textAlign: TextAlign.center, style: LumeText.quote.copyWith(color: AppColors.surface)),
                            AppGaps.h16,
                            Waveform(
                              heights: Waveform.priya,
                              progress: 0,
                              playing: playing,
                              idleColor: AppColors.surface.withValues(alpha: 0.3),
                              duration: Duration(seconds: voice?.seconds ?? 15),
                            ),
                            AppGaps.h16,
                            _PlayButton(playing: playing, enabled: voice != null, onTap: () => context.read<ValueCubit<bool>>().set(!playing)),
                          ],
                        ),
                      ),
                ),
                LumeCard(
                  children: [
                    LumeRow(
                      icon: LumeIcons.mic,
                      title: voice == null ? AppStrings.recordYourVoiceIntro : AppStrings.recordNewOne,
                      subtitle: AppStrings.upTo30Seconds,
                      onTap:
                          () => context.read<ProfileBloc>().add(
                            const ProfileSaved({
                              'voice': {'prompt': kVoicePrompt, 'seconds': 15},
                            }),
                          ),
                    ),
                    if (voice != null)
                      LumeRow(
                        icon: LumeIcons.trash,
                        title: AppStrings.removeVoiceIntro,
                        danger: true,
                        onTap: () => context.read<ProfileBloc>().add(const VoiceIntroRemoved()),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.enabled, required this.onTap});

  final bool playing;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final button = LumeIconButton(
      playing ? LumeIcons.pause : LumeIcons.play,
      size: 64,
      iconSize: 26,
      color: AppColors.ink,
      background: enabled ? AppColors.coral : AppColors.line,
      tooltip: playing ? AppStrings.pause : AppStrings.playVoiceIntro,
      onPressed: enabled ? onTap : null,
    );
    return playing ? Pulse(min: 1, max: 1.08, period: const Duration(milliseconds: 600), child: button) : button;
  }
}
