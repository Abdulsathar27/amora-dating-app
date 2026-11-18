import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/mock_interceptor.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/animations/motion_widgets.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../view_model/auth_bloc.dart';
import '../view_model/phone_auth_cubit.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "What's your number?"
class PhoneNumberView extends StatelessWidget {
  const PhoneNumberView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhoneAuthCubit, PhoneAuthState>(
      builder: (context, s) {
        final cubit = context.read<PhoneAuthCubit>();
        return LumeScaffold(
          header: LumeHeader(onBack: () => context.pop()),
          body: StaggeredEntrance(
            children: [
              AppGaps.h24,
              const LumeTitle(AppStrings.phoneTitle, subtitle: AppStrings.phoneSubtitle),
              AppGaps.h24,
              LumeField(
                label: AppStrings.mobileNumber,
                initialValue: s.phone,
                onChanged: cubit.phoneChanged,
                keyboardType: TextInputType.phone,
                autofocus: true,
                error: s.error,
                helper: AppStrings.messageRates,
              ),
            ],
          ),
          bottom: [
            LumeButton(
              AppStrings.sendCode,
              loading: s.step == PhoneStep.sendingCode,
              onPressed:
                  s.phoneValid
                      ? () async {
                        if (await cubit.sendCode() && context.mounted) context.push(AppRoutes.verifyCode);
                      }
                      : null,
            ),
          ],
        );
      },
    );
  }
}

/// "Enter the code" (+ the error state with red digits and a shake).
class VerifyCodeView extends StatelessWidget {
  const VerifyCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PhoneAuthCubit, PhoneAuthState>(
      listenWhen: (a, b) => b.step == PhoneStep.verified && a.step != b.step,
      listener: (context, s) => context.read<AuthBloc>().add(AuthSignedIn(s.user!)),
      builder: (context, s) {
        final cubit = context.read<PhoneAuthCubit>();
        return LumeScaffold(
          header: LumeHeader(onBack: () => context.pop()),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppGaps.h24,
              LumeTitle(AppStrings.codeTitle, subtitle: AppStrings.codeSentTo(s.phone.trim())),
              AppGaps.h24,
              Shake(trigger: s.shake, child: _CodeBoxes(code: s.code, error: s.codeError, onChanged: cubit.codeChanged)),
              AppGaps.h24,
              AnimatedSwitcher(
                duration: LumeMotion.dissolve,
                child:
                    s.codeError
                        ? Column(
                          key: const ValueKey('error'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LumeNote(s.error ?? AppStrings.codeMismatch, danger: true),
                            AppGaps.h24,
                            _TextLink(AppStrings.sendNewCode, onTap: s.resendIn == 0 ? cubit.resend : null),
                          ],
                        )
                        : s.resendIn > 0
                        ? Text(s.resendLabel, key: const ValueKey('timer'), style: LumeText.labelM.copyWith(color: AppColors.muted))
                        : _TextLink(AppStrings.sendNewCode, key: const ValueKey('resend'), onTap: cubit.resend),
              ),
              if (AppConfig.useMockApi) ...[AppGaps.h24, Text(AppStrings.demoCode(MockInterceptor.demoCode), style: LumeText.caption)],
            ],
          ),
          bottom: [LumeButton(AppStrings.verify, loading: s.step == PhoneStep.verifying, onPressed: s.canVerify ? cubit.verify : null)],
        );
      },
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink(this.label, {super.key, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      GestureDetector(onTap: onTap, child: Text(label, style: LumeText.labelM.copyWith(color: onTap == null ? AppColors.muted : AppColors.plum)));
}

/// Six 50x60 digit boxes over one invisible text field that owns the keyboard.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.code, required this.error, required this.onChanged});

  final String code;
  final bool error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) AppGaps.w8,
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: error ? AppColors.danger : (i == code.length ? AppColors.plum : AppColors.line),
                        width: error || i == code.length ? 2 : 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 140),
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: Text(i < code.length ? code[i] : '', key: ValueKey('$i${i < code.length ? code[i] : ''}'), style: LumeText.titleL),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.01,
              child: TextField(
                autofocus: true,
                onChanged: onChanged,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                showCursor: false,
                decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
