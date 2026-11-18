import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/lume_tokens.dart';
import '../../../core/widgets/animations/entrance.dart';
import '../../../core/widgets/animations/press_scale.dart';
import '../../../core/widgets/lume_components.dart';
import '../../../core/widgets/lume_icon.dart';
import '../../../core/widgets/value_cubit.dart';
import '../../../data/models/message.dart';
import '../../matches/view_model/matches_bloc.dart';
import '../../safety/view/safety_views.dart';
import '../view_model/chat_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

/// "Share something": Photos · Camera · GIFs · Voice.
Future<void> showShareSheet(BuildContext context) {
  final bloc = context.read<ChatBloc>();
  final name = bloc.state.match.profile.name;
  return showLumeSheet<void>(
    context,
    builder:
        (sheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.shareSomething, style: LumeText.titleM.copyWith(color: AppColors.plum)),
              AppGaps.h18,
              StaggeredEntrance(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ShareOption(
                        icon: LumeIcons.image,
                        label: AppStrings.photos,
                        onTap: () {
                          Navigator.pop(sheet);
                          bloc.add(const ChatMediaSent(MessageType.photo, 'assets/images/cafe.jpg'));
                        },
                      ),
                      _ShareOption(
                        icon: LumeIcons.camera,
                        label: AppStrings.camera,
                        onTap: () {
                          Navigator.pop(sheet);
                          showLumeSnack(context, AppStrings.cameraComingSoon);
                        },
                      ),
                      _ShareOption(
                        icon: LumeIcons.smile,
                        label: AppStrings.gifs,
                        onTap: () {
                          Navigator.pop(sheet);
                          showGifPicker(context);
                        },
                      ),
                      _ShareOption(
                        icon: LumeIcons.mic,
                        label: AppStrings.voice,
                        onTap: () {
                          Navigator.pop(sheet);
                          showLumeSnack(context, AppStrings.voiceNotesComingSoon);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              AppGaps.h18,
              LumeNote(AppStrings.photoConsentNote(name), icon: LumeIcons.shield),
            ],
          ),
        ),
  );
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({required this.icon, required this.label, required this.onTap});

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: PressScale(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.lavenderSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: LumeIcon(icon, size: 26),
          ),
          AppGaps.h8,
          Text(label, style: LumeText.labelM),
        ],
      ),
    ),
  );
}

/// GIF picker: search, mood tags, and a 2-column grid.
Future<void> showGifPicker(BuildContext context) {
  final bloc = context.read<ChatBloc>();
  const tags = [AppStrings.gifTrending, AppStrings.gifLaugh, AppStrings.gifYes, AppStrings.gifBlush];
  const gifs = {
    AppStrings.gifTrending: ['assets/images/dunes.jpg', 'assets/images/sea.jpg', 'assets/images/cafe.jpg', 'assets/images/dunes.jpg'],
    AppStrings.gifLaugh: ['assets/images/sea.jpg', 'assets/images/cafe.jpg'],
    AppStrings.gifYes: ['assets/images/dunes.jpg', 'assets/images/sea.jpg'],
    AppStrings.gifBlush: ['assets/images/cafe.jpg', 'assets/images/dunes.jpg'],
  };
  return showLumeSheet<void>(
    context,
    builder:
        (sheet) => BlocProvider(
          create: (_) => ValueCubit<String>(AppStrings.gifTrending),
          child: BlocBuilder<ValueCubit<String>, String>(
            builder:
                (ctx, tag) => SizedBox(
                  height: MediaQuery.sizeOf(ctx).height * 0.62,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: Column(
                      children: [
                        TextField(
                          style: LumeText.bodyL.copyWith(color: AppColors.ink),
                          decoration: InputDecoration(
                            hintText: AppStrings.searchGifs,
                            hintStyle: LumeText.bodyL,
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                          ),
                        ),
                        AppGaps.h14,
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: tags.length,
                            separatorBuilder: (_, _) => AppGaps.w8,
                            itemBuilder:
                                (_, i) => LumeTag(
                                  tags[i],
                                  variant: tags[i] == tag ? TagVariant.selected : TagVariant.normal,
                                  onTap: () => ctx.read<ValueCubit<String>>().set(tags[i]),
                                ),
                          ),
                        ),
                        AppGaps.h14,
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 14,
                            childAspectRatio: 166 / 150,
                            children: [
                              for (final (i, g) in gifs[tag]!.indexed)
                                FadeRise(
                                  key: ValueKey('$tag$i'),
                                  delay: Duration(milliseconds: 50 * i),
                                  child: PressScale(
                                    onTap: () {
                                      Navigator.pop(sheet);
                                      bloc.add(ChatMediaSent(MessageType.gif, g));
                                    },
                                    child: ClipRRect(borderRadius: BorderRadius.circular(18), child: LumePhoto(g)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ),
  );
}

/// Chat "more" menu: view profile, mute, unmatch, block, report.
Future<void> showChatSafetySheet(BuildContext context) {
  final bloc = context.read<ChatBloc>();
  final matches = context.read<MatchesBloc>();
  final p = bloc.state.match.profile;
  return showLumeSheet<void>(
    context,
    builder:
        (sheet) => BlocProvider.value(
          value: bloc,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
            child: BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (a, b) => a.isMuted != b.isMuted,
              builder:
                  (_, s) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LumeRow(
                        icon: LumeIcons.user,
                        title: AppStrings.viewProfileOf(p.name),
                        onTap: () {
                          Navigator.pop(sheet);
                          context.push(AppRoutes.person, extra: FullProfileArgs(p));
                        },
                      ),
                      LumeRow(icon: LumeIcons.bell, title: AppStrings.muteNotifications, toggle: s.isMuted, onToggle: (_) => bloc.add(const ChatMuteToggled())),
                      LumeRow(
                        icon: LumeIcons.close,
                        title: AppStrings.unmatch,
                        subtitle: AppStrings.unmatchSubtitle,
                        danger: true,
                        onTap: () {
                          Navigator.pop(sheet);
                          matches.add(UnmatchRequested(s.match.id));
                          context.go(AppRoutes.messages);
                        },
                      ),
                      LumeRow(
                        icon: LumeIcons.ban,
                        title: AppStrings.block,
                        subtitle: AppStrings.wontBeTold(p.name),
                        danger: true,
                        onTap: () {
                          Navigator.pop(sheet);
                          showBlockSheet(context, p);
                        },
                      ),
                      LumeRow(
                        icon: LumeIcons.flag,
                        title: AppStrings.report,
                        subtitle: AppStrings.ourTeamReviewsEveryReport,
                        danger: true,
                        onTap: () {
                          Navigator.pop(sheet);
                          context.push(AppRoutes.reportReason(p.id, p.name));
                        },
                      ),
                    ],
                  ),
            ),
          ),
        ),
  );
}
