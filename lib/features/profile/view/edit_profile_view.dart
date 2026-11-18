import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/animations/press_scale.dart';
import '../../../core/widgets/lume_components.dart';
import '../../onboarding/view_model/profile_setup_cubit.dart' show kInterestOptions;
import '../view_model/edit_profile_cubit.dart';
import '../view_model/profile_bloc.dart';
import 'my_profile_view.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "Edit profile": photos strip, about, prompt, interests.
class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.read<ProfileBloc>().state.profile;
    if (profile == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => EditProfileCubit(profile),
      child: BlocBuilder<EditProfileCubit, EditProfileState>(
        builder: (context, s) {
          final cubit = context.read<EditProfileCubit>();
          return LumeScaffold(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            header: LumeHeader(title: AppStrings.editProfile, onBack: () => context.pop()),
            body: StaggeredEntrance(
              spacing: 16,
              children: [
                PressScale(
                  scale: 0.98,
                  onTap: () => context.push(AppRoutes.managePhotos),
                  child: Row(
                    children: [
                      for (final (i, photo) in profile.photos.take(3).indexed) ...[
                        if (i > 0) AppGaps.w8,
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 96 / 124,
                            child: LayoutBuilder(
                              builder: (_, b) => ArchPhoto(source: photo, width: b.maxWidth, height: b.maxHeight),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                LumeField(
                  label: AppStrings.aboutYou,
                  initialValue: s.bio,
                  onChanged: cubit.bioChanged,
                  maxLength: EditProfileState.maxBio,
                  maxLines: 3,
                  helper: AppStrings.charactersOf(s.bio.length, EditProfileState.maxBio),
                ),
                if (s.prompt != null) ...[
                  Text(AppStrings.yourPrompts, style: LumeText.titleS.copyWith(color: AppColors.plum)),
                  LumeCard(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(s.prompt!.question, style: LumeText.labelM.copyWith(color: AppColors.muted)),
                      AppGaps.h10,
                      TextFormField(
                        initialValue: s.prompt!.answer,
                        onChanged: cubit.promptAnswerChanged,
                        maxLines: null,
                        style: LumeText.quote,
                        decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
                      ),
                    ],
                  ),
                ],
                Row(
                  children: [
                    Text(AppStrings.interests, style: LumeText.titleS.copyWith(color: AppColors.plum)),
                    const Spacer(),
                    Text(
                      AppStrings.chosenCount(s.interests.length),
                      style: LumeText.labelM.copyWith(color: AppColors.plum),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final i in {...s.interests, ...kInterestOptions})
                      LumeTag(
                        i,
                        variant: s.interests.contains(i) ? TagVariant.lavender : TagVariant.normal,
                        onTap: () => cubit.interestToggled(i),
                      ),
                  ],
                ),
              ],
            ),
            bottom: [SaveProfileButton(label: AppStrings.saveChanges, enabled: s.isDirty, changes: () => s.changes)],
          );
        },
      ),
    );
  }
}
