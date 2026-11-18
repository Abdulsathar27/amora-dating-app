import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "One small promise." — community pledge before profile creation.
class PledgeView extends StatelessWidget {
  const PledgeView({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      (LumeIcons.heart, AppStrings.pledgeRespectTitle, AppStrings.pledgeRespectBody),
      (LumeIcons.check, AppStrings.pledgeConsentTitle, AppStrings.pledgeConsentBody),
      (LumeIcons.smile, AppStrings.pledgeHonestTitle, AppStrings.pledgeHonestBody),
    ];
    return LumeScaffold(
      header: const LumeHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppGaps.h20,
          const FadeRise(child: LumeTitle(AppStrings.pledgeTitle, subtitle: AppStrings.pledgeSubtitle)),
          AppGaps.h20,
          LumeCard(
            children: [
              StaggeredEntrance(children: [for (final r in rows) LumeRow(icon: r.$1, title: r.$2, subtitle: r.$3)]),
            ],
          ),
        ],
      ),
      bottom: [LumeButton(AppStrings.iAgree, onPressed: () => context.push(AppRoutes.createName))],
    );
  }
}
