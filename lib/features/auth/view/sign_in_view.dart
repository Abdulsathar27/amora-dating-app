import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "Glad you're here." — sign-in options.
class SignInView extends StatelessWidget {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    void soon(String what) => showLumeSnack(context, AppStrings.signInComingSoon(what));
    return LumeScaffold(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
      body: StaggeredEntrance(
        spacing: 20,
        children: [
          Text(
            AppStrings.wordmark,
            style: LumeText.wordmark.copyWith(fontSize: 42, height: 48 / 42, color: AppColors.plum),
          ),
          const LumeTitle(AppStrings.signInTitle, subtitle: AppStrings.signInSubtitle),
          Column(
            children: [
              LumeButton(AppStrings.continueWithPhone, onPressed: () => context.push(AppRoutes.phone)),
              AppGaps.h12,
              LumeButton(
                AppStrings.continueWithApple,
                variant: LumeButtonVariant.secondary,
                onPressed: () => soon(AppStrings.apple),
              ),
              AppGaps.h12,
              LumeButton(
                AppStrings.continueWithGoogle,
                variant: LumeButtonVariant.secondary,
                onPressed: () => soon(AppStrings.google),
              ),
              AppGaps.h12,
              LumeButton(
                AppStrings.continueWithEmail,
                variant: LumeButtonVariant.secondary,
                onPressed: () => soon(AppStrings.email),
              ),
            ],
          ),
          Text(AppStrings.signInTerms, textAlign: TextAlign.center, style: LumeText.caption),
        ],
      ),
    );
  }
}
