import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../data/models/match.dart';
import '../../../data/models/message.dart';
import '../../discovery/view/full_profile_view.dart';
import '../../matches/view_model/matches_bloc.dart';
import '../view_model/chat_bloc.dart';
import 'chat_sheets.dart';
import 'message_bubbles.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// Chat with one match. Works for a brand-new match (starters) and an ongoing conversation.
class ChatView extends StatelessWidget {
  const ChatView({super.key, required this.matchId, this.initial});

  final String matchId;
  final Match? initial;

  @override
  Widget build(BuildContext context) {
    final match = initial ?? context.read<MatchesBloc>().state.byId(matchId);
    if (match == null) {
      return LumeScaffold(
        header: LumeHeader(onBack: () => context.pop()),
        scroll: false,
        body: const LumeEmptyState(
          title: AppStrings.conversationEnded,
          body: AppStrings.matchRemoved,
          icon: LumeIcons.chat,
        ),
      );
    }
    return BlocProvider(
      create: (_) => ChatBloc(sl(), match)..add(const ChatOpened()),
      child: BlocListener<ChatBloc, ChatState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, s) => showLumeSnack(context, s.error!),
        child: const _ChatScaffold(),
      ),
    );
  }
}

class _ChatScaffold extends StatelessWidget {
  const _ChatScaffold();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) => context.read<MatchesBloc>().add(const MatchesRequested()),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const _ChatHeader(),
              Expanded(
                child: BlocBuilder<ChatBloc, ChatState>(
                  buildWhen: (a, b) =>
                      a.status != b.status ||
                      a.messages != b.messages ||
                      a.partnerTyping != b.partnerTyping ||
                      a.declined != b.declined ||
                      a.playingId != b.playingId,
                  builder: (context, s) => switch (s.status) {
                    ChatStatus.loading => const Center(child: CircularProgressIndicator(color: AppColors.plum)),
                    _ when s.isNew => _NewMatchStarters(state: s),
                    _ => _MessageList(state: s),
                  },
                ),
              ),
              const _Composer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    final match = context.read<ChatBloc>().state.match;
    final p = match.profile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: [
          LumeIconButton(
            LumeIcons.back,
            tooltip: AppStrings.back,
            onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.messages),
          ),
          AppGaps.w10,
          GestureDetector(
            onTap: () => context.push(AppRoutes.person, extra: FullProfileArgs(p)),
            child: Row(
              children: [
                LumeAvatar(p.mainPhoto, size: AppSizes.avatarSm),
                AppGaps.w10,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(p.name, style: LumeText.titleS),
                        if (p.isVerified) ...[
                          AppGaps.w4,
                          const LumeIcon(LumeIcons.verified, size: 16, color: AppColors.success),
                        ],
                      ],
                    ),
                    if (match.isOnline)
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                          ),
                          AppGaps.w5,
                          Text(AppStrings.onlineNow, style: LumeText.caption.copyWith(color: AppColors.success)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          LumeIconButton(
            LumeIcons.more,
            tooltip: AppStrings.conversationOptions,
            onPressed: () => showChatSafetySheet(context),
          ),
        ],
      ),
    );
  }
}

/// "You and Maya matched today" + conversation starters from their profile.
class _NewMatchStarters extends StatelessWidget {
  const _NewMatchStarters({required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    final p = state.match.profile;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        StaggeredEntrance(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ArchPhoto(source: p.mainPhoto, width: 130, height: 168, shadow: LumeShadows.card),
            AppGaps.h10,
            Text(AppStrings.matchedTodayWith(p.name), style: LumeText.titleS.copyWith(color: AppColors.plum)),
            AppGaps.h10,
            Text(AppStrings.startersFrom(p.name), style: LumeText.bodyM),
            AppGaps.h20,
            for (final s in p.starters) ...[
              StarterChip(text: s, onTap: () => context.read<ChatBloc>().add(ChatSendPressed(s))),
              AppGaps.h8,
            ],
          ],
        ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    final items = buildChatItems(state);
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: items.length + (state.partnerTyping ? 1 : 0),
      itemBuilder: (_, i) {
        if (state.partnerTyping) {
          if (i == 0) {
            return const Align(
              alignment: Alignment.centerLeft,
              child: FadeRise(child: TypingBubble()),
            );
          }
          i -= 1;
        }
        return items[items.length - 1 - i];
      },
    );
  }
}

/// Message field, plus (share) and mic/send. Stateless: the field is rebuilt
/// empty via a new key after each send.
class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChatBloc>();
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (a, b) => a.draftVersion != b.draftVersion || a.hasDraft != b.hasDraft || a.isSending != b.isSending,
      builder: (context, s) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LumeIconButton(
              LumeIcons.plus,
              tooltip: AppStrings.shareSomething,
              background: AppColors.surface,
              bordered: true,
              onPressed: () => showShareSheet(context),
            ),
            AppGaps.w8,
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.only(left: 16, right: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: ValueKey(s.draftVersion),
                        onChanged: (t) => bloc.add(ChatDraftChanged(t)),
                        onSubmitted: (_) => bloc.add(const ChatSendPressed()),
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: LumeText.bodyL.copyWith(color: AppColors.ink),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: AppStrings.messageName(s.match.profile.name),
                          hintStyle: LumeText.bodyL,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    LumeIconButton(
                      LumeIcons.smile,
                      size: 36,
                      iconSize: 20,
                      color: AppColors.muted,
                      tooltip: AppStrings.gifs,
                      onPressed: () => showGifPicker(context),
                    ),
                  ],
                ),
              ),
            ),
            AppGaps.w8,
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: s.hasDraft
                  ? LumeIconButton(
                      LumeIcons.send,
                      key: const ValueKey('send'),
                      tooltip: AppStrings.send,
                      color: AppColors.ink,
                      background: AppColors.coral,
                      onPressed: s.isSending ? null : () => bloc.add(const ChatSendPressed()),
                    )
                  : LumeIconButton(
                      LumeIcons.mic,
                      key: const ValueKey('mic'),
                      tooltip: AppStrings.recordVoiceNote,
                      color: AppColors.ink,
                      background: AppColors.coral,
                      onPressed: () => showLumeSnack(context, AppStrings.voiceNotesComingSoon),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reaction bar + message menu over a scrim (long-press on a bubble).
Future<void> showReactions(BuildContext context, Message message) {
  final bloc = context.read<ChatBloc>()..add(ChatMessageSelected(message));
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: AppStrings.closeReactions,
    barrierColor: AppColors.ink.withValues(alpha: 0.55),
    transitionDuration: LumeMotion.dissolve,
    pageBuilder: (ctx, _, _) => BlocProvider.value(
      value: bloc,
      child: _ReactionOverlay(message: message),
    ),
    transitionBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
  ).whenComplete(() {
    if (!bloc.isClosed && bloc.state.selected != null) bloc.add(const ChatMessageSelected(null));
  });
}

class _ReactionOverlay extends StatelessWidget {
  const _ReactionOverlay({required this.message});

  final Message message;

  static const _reactions = [LumeIcons.heart, LumeIcons.smile, LumeIcons.star, LumeIcons.discover, LumeIcons.check];

  @override
  Widget build(BuildContext context) {
    final mine = message.senderId == 'me';
    void react(String r) {
      context.read<ChatBloc>().add(ChatReacted(r));
      Navigator.of(context).pop();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Pops in with a bouncy scale.
            _PopIn(
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: LumeShadows.card),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final r in _reactions)
                        LumeIconButton(
                          r,
                          tooltip: r,
                          iconSize: 24,
                          color: switch (r) {
                            LumeIcons.heart => AppColors.coral,
                            LumeIcons.check => AppColors.success,
                            _ => AppColors.plum,
                          },
                          background: message.reaction == r ? AppColors.lavenderSoft : null,
                          onPressed: () => react(r),
                        ),
                      LumeIconButton(
                        LumeIcons.plus,
                        tooltip: AppStrings.moreReactions,
                        color: AppColors.muted,
                        background: AppColors.background,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AppGaps.h10,
            IgnorePointer(
              child: MessageBubble(message: message, mine: mine),
            ),
            AppGaps.h8,
            _PopIn(
              delay: 60,
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 220,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MenuItem(
                        icon: LumeIcons.undo,
                        label: AppStrings.reply,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      if (message.type == MessageType.text)
                        _MenuItem(
                          icon: LumeIcons.edit,
                          label: AppStrings.copyText,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: message.text));
                            Navigator.of(context).pop();
                          },
                        ),
                      if (!mine)
                        _MenuItem(
                          icon: LumeIcons.flag,
                          label: AppStrings.reportMessage,
                          danger: true,
                          onTap: () {
                            final p = context.read<ChatBloc>().state.match.profile;
                            Navigator.of(context).pop();
                            context.push(AppRoutes.reportReason(p.id, p.name));
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.danger = false});

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            LumeIcon(icon, size: 20, color: danger ? AppColors.danger : AppColors.plum),
            AppGaps.w10,
            Text(label, style: LumeText.labelM.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Scale-from-0.6 entrance with a slight overshoot, on its own AnimationController.
class _PopIn extends StatefulWidget {
  const _PopIn({required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _c,
    child: ScaleTransition(
      scale: Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack)),
      child: widget.child,
    ),
  );
}
