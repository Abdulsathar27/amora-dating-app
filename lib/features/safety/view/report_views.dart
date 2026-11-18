import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../data/models/settings.dart';
import '../../discovery/view_model/discovery_bloc.dart';
import '../../matches/view_model/matches_bloc.dart';
import '../view_model/safety_cubits.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// Report step 1: "What happened?"
class ReportReasonView extends StatelessWidget {
  const ReportReasonView({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportCubit>();
    return LumeScaffold(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      header: LumeHeader(title: AppStrings.report, close: true, onBack: () => context.pop()),
      body: StaggeredEntrance(
        spacing: 14,
        children: [
          LumeTitle(AppStrings.reportTitle, subtitle: name.isEmpty ? AppStrings.reportConfidential : AppStrings.reportAbout(name)),
          LumeCard(
            children: [
              for (final r in ReportReason.values)
                LumeRow(
                  title: r.label,
                  onTap: () {
                    cubit.reasonPicked(r);
                    context.push(AppRoutes.reportDetails(cubit.userId, name));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Report step 2: "Tell us a little more."
class ReportDetailsView extends StatelessWidget {
  const ReportDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, s) {
        final cubit = context.read<ReportCubit>();
        return LumeScaffold(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          header: LumeHeader(title: AppStrings.report, onBack: () => context.pop()),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepProgress(step: 2, total: 2),
              AppGaps.h14,
              const FadeRise(child: LumeTitle(AppStrings.reportMoreTitle, subtitle: AppStrings.reportMoreSubtitle)),
              AppGaps.h14,
              LumeField(
                label: s.reason?.label ?? AppStrings.details,
                initialValue: s.details,
                onChanged: cubit.detailsChanged,
                maxLines: 4,
                maxLength: 500,
                hint: AppStrings.reportTitle,
              ),
              AppGaps.h14,
              LumeCard(children: [LumeRow(title: AppStrings.alsoBlock, toggle: s.alsoBlock, onToggle: cubit.alsoBlockChanged)]),
              if (s.error != null) ...[AppGaps.h14, LumeNote(s.error!, danger: true)],
            ],
          ),
          bottom: [
            LumeButton(
              AppStrings.sendReport,
              loading: s.submitting,
              onPressed: () async {
                final matches = context.read<MatchesBloc>();
                final discovery = context.read<DiscoveryBloc>();
                if (!await cubit.submit()) return;
                if (s.alsoBlock) {
                  matches.add(MatchRemoved(cubit.userId));
                  discovery.add(const DiscoveryStarted());
                }
                if (context.mounted) context.go(AppRoutes.reportSent);
              },
            ),
          ],
        );
      },
    );
  }
}

/// "Thank you for telling us."
class ReportSentView extends StatelessWidget {
  const ReportSentView({super.key});

  @override
  Widget build(BuildContext context) {
    return LumeScaffold(
      scroll: false,
      body: const LumeEmptyState(icon: LumeIcons.shield, title: AppStrings.reportThanksTitle, body: AppStrings.reportThanksBody),
      bottom: [LumeButton(AppStrings.done, onPressed: () => context.go(AppRoutes.messages))],
    );
  }
}
