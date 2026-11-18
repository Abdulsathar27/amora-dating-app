import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/animations/motion_widgets.dart';
import '../../../core/widgets/lume_button.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../core/widgets/waveform.dart';
import '../../../data/models/message.dart';
import '../view_model/chat_bloc.dart';
import 'chat_view.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

String _time(DateTime at) => DateFormat('h:mm a').format(at.toLocal()).toLowerCase();

String _day(DateTime at) {
  final d = at.toLocal();
  final now = DateTime.now();
  if (DateUtils.isSameDay(d, now)) return AppStrings.today;
  if (DateUtils.isSameDay(d, now.subtract(const Duration(days: 1)))) return AppStrings.yesterday;
  return DateFormat.MMMEd().format(d);
}

/// Turns the message list into rows: day dividers, bubbles, and a time caption
/// under the last message of each run from the same sender.
List<Widget> buildChatItems(ChatState s) {
  final out = <Widget>[];
  final msgs = s.messages;
  for (var i = 0; i < msgs.length; i++) {
    final m = msgs[i];
    final prev = i > 0 ? msgs[i - 1] : null;
    final next = i + 1 < msgs.length ? msgs[i + 1] : null;
    if (prev == null || !DateUtils.isSameDay(prev.sentAt.toLocal(), m.sentAt.toLocal())) {
      out.add(Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Center(child: Text(_day(m.sentAt), style: LumeText.caption))));
    }
    final mine = m.senderId == 'me';
    final lastOfRun = next == null || next.senderId != m.senderId || next.sentAt.difference(m.sentAt).inMinutes > 5;
    out.add(
      FadeRise(
        key: ValueKey(m.id),
        offset: 8,
        duration: const Duration(milliseconds: 260),
        child: Padding(
          padding: EdgeInsets.only(bottom: lastOfRun ? 12 : 4),
          child: _MessageRow(message: m, mine: mine, showTime: lastOfRun, declined: s.declined.contains(m.id), playing: s.playingId == m.id),
        ),
      ),
    );
  }
  return out;
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.mine, required this.showTime, required this.declined, required this.playing});

  final Message message;
  final bool mine;
  final bool showTime;
  final bool declined;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final caption = switch (m.type) {
      MessageType.photo when !mine && !m.isHidden => AppStrings.sentPhotoAt(_time(m.sentAt)),
      _ when mine => AppStrings.readAt(_time(m.sentAt)),
      _ => _time(m.sentAt),
    };
    final hasReaction = m.reaction != null && m.reaction!.isNotEmpty;
    return Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: m.isHidden ? null : () => showReactions(context, m),
          child: m.isHidden && !mine ? _HiddenPhoto(message: m, declined: declined) : MessageBubble(message: m, mine: mine, playing: playing),
        ),
        if (hasReaction)
          Transform.translate(
            offset: const Offset(0, -4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LumeIcon(m.reaction!, size: 14, color: m.reaction == LumeIcons.heart ? AppColors.coral : AppColors.plum),
                  AppGaps.w4,
                  Text('1', style: LumeText.caption),
                ],
              ),
            ),
          ),
        if (showTime) ...[AppGaps.h3, Text(caption, style: LumeText.caption)],
      ],
    );
  }
}

/// Bubble/Incoming · Bubble/Outgoing, plus voice, photo and GIF variants.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.mine, this.playing = false});

  final Message message;
  final bool mine;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(mine ? 20 : 6),
      bottomRight: Radius.circular(mine ? 6 : 20),
    );
    final m = message;
    switch (m.type) {
      case MessageType.photo:
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(110),
            topRight: const Radius.circular(110),
            bottomLeft: Radius.circular(mine ? 20 : 6),
            bottomRight: Radius.circular(mine ? 6 : 20),
          ),
          child: SizedBox(width: 220, height: 250, child: LumePhoto(m.mediaUrl)),
        );
      case MessageType.gif:
        return ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            width: 200,
            height: 150,
            child: Stack(fit: StackFit.expand, children: [LumePhoto(m.mediaUrl), const Positioned(left: 10, top: 10, child: LumeTag(AppStrings.gif))]),
          ),
        );
      case MessageType.voice:
        return Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          decoration: BoxDecoration(color: mine ? AppColors.plum : AppColors.surface, borderRadius: radius),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LumeIconButton(
                playing ? LumeIcons.pause : LumeIcons.play,
                tooltip: playing ? AppStrings.pause : AppStrings.playVoiceMessage,
                iconSize: 18,
                color: AppColors.ink,
                background: AppColors.coral,
                onPressed: () => context.read<ChatBloc>().add(ChatVoicePlayed(m.id)),
              ),
              AppGaps.w10,
              Waveform(
                heights: const [8, 14, 20, 11, 22, 16, 9, 18, 24, 12, 10, 19, 15, 8, 14, 20, 11],
                progress: playing ? 0 : 0.18,
                playing: playing,
                duration: Duration(seconds: m.voiceSeconds ?? 10),
              ),
              AppGaps.w10,
              Text('0:${(m.voiceSeconds ?? 0).toString().padLeft(2, '0')}', style: LumeText.caption),
            ],
          ),
        );
      case MessageType.text:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: mine ? AppColors.plum : AppColors.surface, borderRadius: radius),
            child: Text(m.text, style: LumeText.bodyL.copyWith(color: mine ? AppColors.surface : AppColors.ink)),
          ),
        );
    }
  }
}

/// "Maya sent a photo — it stays hidden until you choose to see it."
class _HiddenPhoto extends StatelessWidget {
  const _HiddenPhoto({required this.message, required this.declined});

  final Message message;
  final bool declined;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChatBloc>();
    final name = bloc.state.match.profile.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 250,
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: AppColors.lavenderSoft,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
            ),
          ),
          child: Column(
            children: [
              AppGaps.h19,
              const LumeIcon(LumeIcons.eyeoff, size: 40),
              AppGaps.h10,
              Text(AppStrings.sentAPhoto(name), style: LumeText.titleS.copyWith(color: AppColors.plum)),
              AppGaps.h10,
              Text(AppStrings.photoHiddenBody, textAlign: TextAlign.center, style: LumeText.bodyM),
              AppGaps.h10,
              LumeButton(
                AppStrings.viewPhoto,
                variant: LumeButtonVariant.plum,
                height: AppSizes.buttonHeightSm,
                onPressed: () => bloc.add(ChatPhotoRevealed(message.id)),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: LumeMotion.dissolve,
          child:
              declined
                  ? const SizedBox(width: 250)
                  : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LumeButton(
                          AppStrings.notNow,
                          expand: false,
                          variant: LumeButtonVariant.ghost,
                          height: AppSizes.buttonHeightSm,
                          onPressed: () => bloc.add(ChatPhotoDeclined(message.id)),
                        ),
                        AppGaps.w8,
                        LumeButton(
                          AppStrings.report,
                          expand: false,
                          variant: LumeButtonVariant.danger,
                          height: AppSizes.buttonHeightSm,
                          onPressed: () {
                            final p = bloc.state.match.profile;
                            context.push(AppRoutes.reportReason(p.id, p.name));
                          },
                        ),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }
}

/// Incoming bubble with three animated dots.
class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
        bottomLeft: Radius.circular(6),
      ),
    ),
    child: Semantics(label: AppStrings.typing, child: const TypingDots()),
  );
}
