import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/press_scale.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../likes/view_model/likes_bloc.dart';
import '../../matches/view_model/matches_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// Holds the five tabs (StatefulShellRoute) and the floating Lumé nav bar.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: LumeNavBar(
        index: shell.currentIndex,
        onSelect: (i) {
          if (i == 1) context.read<LikesBloc>().add(const LikesRequested());
          if (i == 2 || i == 3) context.read<MatchesBloc>().add(const MatchesRequested());
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
      ),
    );
  }
}

class _Tab {
  const _Tab(this.icon, this.label);
  final String icon;
  final String label;
}

/// Floating 72px pill nav. The lavender indicator slides between tabs on an
/// AnimationController; the selected icon gets a small bounce.
class LumeNavBar extends StatefulWidget {
  const LumeNavBar({super.key, required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const tabs = [
    _Tab(LumeIcons.discover, AppStrings.tabDiscover),
    _Tab(LumeIcons.heart, AppStrings.tabLikes),
    _Tab(LumeIcons.matches, AppStrings.tabMatches),
    _Tab(LumeIcons.chat, AppStrings.tabMessages),
    _Tab(LumeIcons.user, AppStrings.tabProfile),
  ];

  @override
  State<LumeNavBar> createState() => _LumeNavBarState();
}

class _LumeNavBarState extends State<LumeNavBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1);
  late int _from = widget.index;

  @override
  void didUpdateWidget(LumeNavBar old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _from = old.index;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<MatchesBloc, int>((b) => b.state.unreadTotal);
    final likes = context.select<LikesBloc, int>((b) => b.state.likes.length);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: AppSizes.navBarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(36), boxShadow: LumeShadows.card),
        child: LayoutBuilder(
          builder: (_, box) {
            final w = box.maxWidth / LumeNavBar.tabs.length;
            return AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                final t = Curves.easeOutBack.transform(_c.value);
                final x = (_from + (widget.index - _from) * t) * w + (w - 52) / 2;
                return Stack(
                  children: [
                    Positioned(
                      left: x,
                      top: 2,
                      child: Container(
                        width: 52,
                        height: 32,
                        decoration: BoxDecoration(color: AppColors.lavenderSoft, borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < LumeNavBar.tabs.length; i++)
                          Expanded(
                            child: _NavItem(
                              tab: LumeNavBar.tabs[i],
                              selected: i == widget.index,
                              bounce: i == widget.index ? Curves.elasticOut.transform(_c.value) : 1,
                              badge: switch (i) {
                                1 => likes,
                                3 => unread,
                                _ => 0,
                              },
                              onTap: () => widget.onSelect(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.selected, required this.bounce, required this.badge, required this.onTap});

  final _Tab tab;
  final bool selected;
  final double bounce;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.plum : AppColors.muted;
    return Semantics(
      selected: selected,
      button: true,
      label: badge > 0 ? AppStrings.tabBadge(tab.label, badge) : tab.label,
      child: PressScale(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 32,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(scale: selected ? 0.85 + 0.15 * bounce : 1, child: LumeIcon(tab.icon, color: color)),
                    if (badge > 0)
                      Positioned(
                        right: -4,
                        top: 2,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(color: AppColors.coral, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 1.5)),
                        ),
                      ),
                  ],
                ),
              ),
              AppGaps.h3,
              Text(tab.label, maxLines: 1, style: LumeText.caption.copyWith(color: color, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
