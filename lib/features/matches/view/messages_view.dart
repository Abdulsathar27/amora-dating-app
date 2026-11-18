import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/animations/press_scale.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../data/models/match.dart';
import '../view_model/matches_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "Messages": conversation list + safety note, and the empty state.
class MessagesView extends StatelessWidget {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<MatchesBloc, MatchesState>(
          builder: (context, s) {
            if (s.status == MatchesStatus.loading) return const Center(child: CircularProgressIndicator(color: AppColors.plum));
            if (s.conversations.isEmpty) {
              return LumeEmptyState(
                icon: LumeIcons.chat,
                title: AppStrings.messagesEmptyTitle,
                body: AppStrings.messagesEmptyBody,
                actionLabel: AppStrings.seeMyMatches,
                onAction: () => context.go(AppRoutes.matches),
              );
            }
            return RefreshIndicator(
              color: AppColors.plum,
              onRefresh: () async => context.read<MatchesBloc>().add(const MatchesRequested()),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  const FadeRise(child: LumeTitle(AppStrings.messages)),
                  AppGaps.h16,
                  LumeCard(
                    children: [
                      StaggeredEntrance(children: [for (final m in s.conversations) _ConversationRow(match: m)]),
                    ],
                  ),
                  AppGaps.h16,
                  const LumeNote(AppStrings.moneyWarning, icon: LumeIcons.shield),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final last = match.lastMessage!;
    final mine = last.senderId == 'me';
    final unread = match.unreadCount > 0;
    final preview = mine ? AppStrings.youPreview(last.preview) : last.preview;
    return Semantics(
      button: true,
      label: '${match.profile.name}. $preview${unread ? AppStrings.unreadSuffix(match.unreadCount) : ''}',
      child: PressScale(
        scale: 0.98,
        onTap: () => context.push(AppRoutes.chat(match.id), extra: match),
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                LumeAvatar(match.profile.mainPhoto, size: AppSizes.avatarLg),
                AppGaps.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Expanded(child: Text(match.profile.name, style: LumeText.titleS)), Text(shortTime(last.sentAt), style: LumeText.caption)]),
                      AppGaps.h2,
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LumeText.bodyM.copyWith(color: unread ? AppColors.ink : AppColors.muted),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text('${match.unreadCount}', style: LumeText.caption.copyWith(color: AppColors.ink)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "2m", "1h", "Tue", "Mon", "3 Nov".
String shortTime(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return AppStrings.now;
  if (diff.inMinutes < 60) return AppStrings.minutesShort(diff.inMinutes);
  if (diff.inHours < 24) return AppStrings.hoursShort(diff.inHours);
  if (diff.inDays < 7) return DateFormat.E().format(at.toLocal());
  return DateFormat.MMMd().format(at.toLocal());
}
