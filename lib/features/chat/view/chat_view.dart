import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/message.dart';
import '../../../data/models/relationship.dart';
import '../../auth/view_model/auth_bloc.dart';
import '../../matches/view/matches_view.dart';
import '../../relationship/view_model/relationship_bloc.dart';
import '../view_model/chat_bloc.dart';

enum _ChatMenu { profile, partner, unmatch }

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final match = context.read<ChatBloc>().state.match;
    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, s) => showSnack(context, s.error!),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0,
          title: InkWell(
            onTap: () => AppRouter.openProfileDetail(context, match.profile),
            child: Row(children: [
              Avatar(match.profile.mainPhoto, size: 38),
              const SizedBox(width: 10),
              Text(match.profile.name),
            ]),
          ),
          actions: [
            PopupMenuButton<_ChatMenu>(
              onSelected: (v) => switch (v) {
                _ChatMenu.profile => AppRouter.openProfileDetail(context, match.profile),
                _ChatMenu.partner => _askPartner(context),
                _ChatMenu.unmatch => confirmUnmatch(context, match, popAfter: true),
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: _ChatMenu.profile, child: Text('View profile')),
                PopupMenuItem(value: _ChatMenu.partner, child: Text('Ask to be partners 💞')),
                PopupMenuItem(value: _ChatMenu.unmatch, child: Text('Unmatch')),
              ],
            ),
          ],
        ),
        body: const SafeArea(
          child: Column(children: [Expanded(child: _MessageList()), _Composer()]),
        ),
      ),
    );
  }

  Future<void> _askPartner(BuildContext context) async {
    final rel = context.read<RelationshipBloc>();
    final match = context.read<ChatBloc>().state.match;
    if (rel.state.relationship.status != RelationshipStatus.none) {
      return showSnack(context, 'You already have a partner or a pending request.');
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Make it official with ${match.profile.name}?'),
        content: const Text(
          'If they accept, you both unlock the "Us" space: shared date plans, memories, mood check-ins and your anniversary countdown.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send request')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      rel.add(PartnerRequestSent(match.id));
      showSnack(context, 'Request sent to ${match.profile.name}');
    }
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList();

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthBloc>().state.user?.id ?? 'me';
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (a, b) => a.messages != b.messages || a.status != b.status,
      builder: (context, s) {
        if (s.status == ChatStatus.loading) return const LoadingView();
        if (s.status == ChatStatus.failure && s.messages.isEmpty) {
          return ErrorView(message: s.error ?? 'Error', onRetry: () => context.read<ChatBloc>().add(const ChatOpened()));
        }
        if (s.messages.isEmpty) return _Icebreakers(state: s);
        final reversed = s.messages.reversed.toList();
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: reversed.length,
          itemBuilder: (_, i) {
            final msg = reversed[i];
            final older = i + 1 < reversed.length ? reversed[i + 1] : null;
            final showDay = older == null || !DateUtils.isSameDay(older.sentAt.toLocal(), msg.sentAt.toLocal());
            return Column(children: [
              if (showDay) _DayDivider(msg.sentAt),
              _Bubble(message: msg, isMine: msg.senderId == myId),
            ]);
          },
        );
      },
    );
  }
}

class _Icebreakers extends StatelessWidget {
  const _Icebreakers({required this.state});
  final ChatState state;

  @override
  Widget build(BuildContext context) {
    final p = state.match.profile;
    final prompt = p.prompts.isEmpty ? null : p.prompts.first;
    final suggestions = [
      if (prompt != null) 'Okay, "${prompt.answer}" – tell me more!',
      if (p.interests.isNotEmpty) 'I see you are into ${p.interests.first}. Favourite spot for it?',
      'Hey ${p.name}! What does your perfect weekend look like?',
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(child: Avatar(p.mainPhoto, size: 110, ring: true)),
        const SizedBox(height: 16),
        Text('You matched with ${p.name}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text('Break the ice with one of these:', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        for (final s in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ActionChip(
              label: Text(s, softWrap: true),
              onPressed: () => context.read<ChatBloc>().add(ChatSendPressed(s)),
            ),
          ),
      ],
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider(this.at);
  final DateTime at;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(DateFormat.yMMMd().format(at.toLocal()), style: Theme.of(context).textTheme.labelSmall),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine});
  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isMine ? AppColors.brandGradient : null,
            color: isMine ? null : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(message.text, style: TextStyle(color: isMine ? Colors.white : scheme.onSurface, fontSize: 15)),
              const SizedBox(height: 2),
              Text(
                DateFormat.jm().format(message.sentAt.toLocal()),
                style: TextStyle(fontSize: 10, color: isMine ? Colors.white70 : scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChatBloc>();
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (a, b) =>
          a.draftVersion != b.draftVersion ||
          a.canSend != b.canSend ||
          a.isSending != b.isSending ||
          a.messages.isEmpty != b.messages.isEmpty,
      builder: (context, s) {
        final enabled = s.match.canSendFirstMessage || s.messages.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  // New key after each send => fresh, empty field without a controller.
                  key: ValueKey(s.draftVersion),
                  enabled: enabled,
                  onChanged: (t) => bloc.add(ChatDraftChanged(t)),
                  onSubmitted: (_) => bloc.add(const ChatSendPressed()),
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: enabled ? 'Type a message' : 'Waiting for ${s.match.profile.name} to make the first move',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: s.canSend ? () => bloc.add(const ChatSendPressed()) : null,
                icon: s.isSending
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        );
      },
    );
  }
}
