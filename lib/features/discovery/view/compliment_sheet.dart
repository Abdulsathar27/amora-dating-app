import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../data/models/profile.dart';
import '../view_model/compliment_cubit.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "Send Maya a compliment". Returns the text, or null if dismissed.
Future<String?> showComplimentSheet(BuildContext context, Profile profile) {
  return showLumeSheet<String>(context, builder: (_) => BlocProvider(create: (_) => ComplimentCubit(), child: ComplimentSheet(profile: profile)));
}

class ComplimentSheet extends StatelessWidget {
  const ComplimentSheet({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ComplimentCubit>();
    return BlocBuilder<ComplimentCubit, ComplimentState>(
      builder:
          (context, s) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LumeAvatar(profile.mainPhoto),
                    AppGaps.w12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.complimentTitle(profile.name), style: LumeText.titleM.copyWith(color: AppColors.plum)),
                          AppGaps.h2,
                          Text(AppStrings.complimentHint, style: LumeText.bodyM),
                        ],
                      ),
                    ),
                  ],
                ),
                AppGaps.h14,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (i, sug) in ComplimentCubit.suggestionsFor(profile).indexed)
                      LumeTag(sug, variant: i == 3 || s.text == sug ? TagVariant.lavender : TagVariant.normal, onTap: () => cubit.suggestionPicked(sug)),
                  ],
                ),
                AppGaps.h14,
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.plum, width: 2),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        key: ValueKey(s.version),
                        initialValue: s.text,
                        autofocus: true,
                        onChanged: cubit.changed,
                        maxLines: 3,
                        minLines: 3,
                        maxLength: ComplimentState.maxLength,
                        style: LumeText.bodyL.copyWith(color: AppColors.ink),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          counterText: '',
                          hintText: AppStrings.complimentPlaceholder,
                          hintStyle: LumeText.bodyL,
                        ),
                      ),
                      AppGaps.h8,
                      Align(alignment: Alignment.centerRight, child: Text(s.counter, style: LumeText.caption)),
                    ],
                  ),
                ),
                AppGaps.h14,
                LumeNote(AppStrings.complimentNote(profile.name), icon: LumeIcons.info),
                AppGaps.h14,
                LumeButton(AppStrings.sendCompliment, onPressed: s.canSend ? () => Navigator.of(context).pop(s.text.trim()) : null),
              ],
            ),
          ),
    );
  }
}
