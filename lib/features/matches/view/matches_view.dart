import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/match.dart';
import '../view_model/matches_bloc.dart';

class MatchesView extends StatelessWidget {
  const MatchesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: BlocConsumer<MatchesBloc, MatchesState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, s) => showSnack(context, s.error!),
        builder: (context, s) {
          final bloc = context.read<MatchesBloc>();
          if (s.status == MatchesStatus.loading) return const LoadingView();
          if (s.status == MatchesStatus.failure) {
            return ErrorView(message: s.error ?? 'Error', onRetry: () => bloc.add(const MatchesRequested()));
          }
          if (s.matches.isEmpty) {
            return const EmptyView(
              icon: Icons.chat_bubble_outline,
              title: 'No matches yet',
              subtitle: 'Start swiping – your matches and conversations will show up here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => bloc.add(const MatchesRequested()),
            child: ListView(
              children: [
                if (s.newMatches.isNotEmpty) ...[
                  const _SectionTitle('New matches'),
                  SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: s.newMatches.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => _NewMatchBubble(match: s.newMatches[i]),
                    ),
                  ),
                ],
                const _SectionTitle('Messages'),
                if (s.conversations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Say hi to one of your new matches!', textAlign: TextAlign.center),
                  ),
                for (final m in s.conversations) _ConversationTile(match: m),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
      );
}

String? _expiryLabel(Match m) {
  final exp = m.expiresAt;
  if (exp == null) return null;
  final left = exp.difference(DateTime.now());
  if (left.isNegative) return 'Expired';
  return left.inHours >= 1 ? '${left.inHours}h left' : '${left.inMinutes}m left';
}

class _NewMatchBubble extends StatelessWidget {
  const _NewMatchBubble({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    final expiry = _expiryLabel(match);
    return GestureDetector(
      onTap: () => AppRouter.openChat(context, match),
      onLongPress: () => confirmUnmatch(context, match),
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Avatar(match.profile.mainPhoto, size: 72, ring: true),
            const SizedBox(height: 6),
            Text(match.profile.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (expiry != null) Text(expiry, style: const TextStyle(fontSize: 11, color: AppColors.rewind)),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    final last = match.lastMessage!;
    final unread = match.unreadCount > 0;
    final time = last.sentAt.toLocal();
    final isToday = DateUtils.isSameDay(time, DateTime.now());
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Avatar(match.profile.mainPhoto, size: 56),
      title: Text(match.profile.name, style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.w600)),
      subtitle: Text(
        last.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: unread ? FontWeight.w600 : FontWeight.normal),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(isToday ? DateFormat.jm().format(time) : DateFormat.MMMd().format(time), style: const TextStyle(fontSize: 12)),
          if (unread) ...[
            const SizedBox(height: 4),
            Badge(label: Text('${match.unreadCount}'), backgroundColor: AppColors.primary),
          ],
        ],
      ),
      onTap: () => AppRouter.openChat(context, match),
      onLongPress: () => confirmUnmatch(context, match),
    );
  }
}

Future<void> confirmUnmatch(BuildContext context, Match match, {bool popAfter = false}) async {
  final bloc = context.read<MatchesBloc>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Unmatch ${match.profile.name}?'),
      content: const Text('You will no longer see each other and your conversation will be deleted.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unmatch', style: TextStyle(color: AppColors.nope))),
      ],
    ),
  );
  if (ok != true) return;
  bloc.add(UnmatchRequested(match.id));
  if (popAfter && context.mounted) Navigator.of(context).pop();
}
