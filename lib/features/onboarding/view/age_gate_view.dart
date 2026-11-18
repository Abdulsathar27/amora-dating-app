import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../auth/view_model/age_gate_cubit.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "First, your birthday." — 18+ gate.
class AgeGateView extends StatelessWidget {
  const AgeGateView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AgeGateCubit(),
      child: BlocBuilder<AgeGateCubit, AgeGateState>(
        builder: (context, s) {
          final cubit = context.read<AgeGateCubit>();
          return LumeScaffold(
            header: LumeHeader(onBack: () => context.pop()),
            body: StaggeredEntrance(
              children: [
                AppGaps.h24,
                const LumeTitle(AppStrings.ageGateTitle, subtitle: AppStrings.ageGateSubtitle),
                AppGaps.h24,
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: AppStrings.day,
                        hint: AppStrings.dayHint,
                        maxLength: 2,
                        onChanged: cubit.dayChanged,
                        autofocus: true,
                      ),
                    ),
                    AppGaps.w12,
                    Expanded(
                      child: _DateField(
                        label: AppStrings.month,
                        hint: AppStrings.monthHint,
                        maxLength: 2,
                        onChanged: cubit.monthChanged,
                      ),
                    ),
                    AppGaps.w12,
                    Expanded(
                      child: _DateField(
                        label: AppStrings.year,
                        hint: AppStrings.yearHint,
                        maxLength: 4,
                        onChanged: cubit.yearChanged,
                      ),
                    ),
                  ],
                ),
                AppGaps.h24,
                const LumeNote(AppStrings.ageGateNote, icon: LumeIcons.lock),
              ],
            ),
            bottom: [
              LumeButton(
                AppStrings.confirmAdult,
                onPressed:
                    s.isComplete
                        ? () => s.isAdult() ? context.push(AppRoutes.signIn) : context.go(AppRoutes.ageBlocked)
                        : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.hint,
    required this.maxLength,
    required this.onChanged,
    this.autofocus = false,
  });

  final String label;
  final String hint;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: c, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: LumeText.labelM),
        AppGaps.h8,
        TextField(
          autofocus: autofocus,
          onChanged: onChanged,
          maxLength: maxLength,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: LumeText.titleM,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: LumeText.titleM.copyWith(color: AppColors.line),
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: border(AppColors.line, 1.5),
            focusedBorder: border(AppColors.plum, 2),
          ),
        ),
      ],
    );
  }
}

/// "Lumé is for adults only."
class AgeBlockedView extends StatelessWidget {
  const AgeBlockedView({super.key});

  @override
  Widget build(BuildContext context) {
    return LumeScaffold(
      scroll: false,
      body: const LumeEmptyState(
        icon: LumeIcons.shield,
        title: AppStrings.ageBlockedTitle,
        body: AppStrings.ageBlockedBody,
      ),
      bottom: [
        LumeButton(
          AppStrings.close,
          variant: LumeButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.welcome),
        ),
      ],
    );
  }
}
