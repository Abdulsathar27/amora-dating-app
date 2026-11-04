import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/match.dart';
import '../../discovery/view/discovery_view.dart';
import '../../matches/view_model/matches_bloc.dart';
import '../view_model/likes_bloc.dart';

class LikesView extends StatelessWidget {
  const LikesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LikesBloc, LikesState>(
      listenWhen: (a, b) => (b.newMatch != null && a.newMatch != b.newMatch) || (b.error != null && a.error != b.error),
      listener: (context, s) {
        if (s.error != null) showSnack(context, s.error!);
        if (s.newMatch != null) {
          context.read<LikesBloc>().add(const LikesMatchSeen());
          context.read<MatchesBloc>().add(const MatchesRequested());
          showMatchDialog(context, s.newMatch!);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Likes You')),
        body: BlocBuilder<LikesBloc, LikesState>(
          builder: (context, s) {
            final bloc = context.read<LikesBloc>();
            if (s.status == LikesStatus.loading) return const LoadingView();
            if (s.status == LikesStatus.failure) {
              return ErrorView(message: s.error ?? 'Error', onRetry: () => bloc.add(const LikesRequested()));
            }
            if (s.likes.isEmpty) {
              return const EmptyView(
                icon: Icons.favorite_border,
                title: 'No likes yet',
                subtitle: 'Complete your profile with great photos and prompts to stand out.',
              );
            }
            return RefreshIndicator(
              onRefresh: () async => bloc.add(const LikesRequested()),
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: s.likes.length,
                itemBuilder: (_, i) => _LikeTile(like: s.likes[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LikeTile extends StatelessWidget {
  const _LikeTile({required this.like});
  final ReceivedLike like;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LikesBloc>();
    final p = like.profile;
    void respond(bool yes) => bloc.add(LikeResponded(like, likeBack: yes));

    return GestureDetector(
      onTap: () => AppRouter.openProfileDetail(
        context,
        p,
        actions: Builder(
          builder: (ctx) => Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  respond(false);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Pass'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientButton(
                label: 'Like back',
                onPressed: () {
                  respond(true);
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ]),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkPhoto(p.mainPhoto),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.45, 1],
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            if (like.isSuperLike)
              const Positioned(
                top: 8,
                left: 8,
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.superLike,
                  avatar: Icon(Icons.star, color: Colors.white, size: 16),
                  label: Text('Super Like', style: TextStyle(color: Colors.white)),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p.name}, ${p.age}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  if (like.comment != null)
                    Text('"${like.comment}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MiniButton(icon: Icons.close, color: AppColors.nope, onTap: () => respond(false)),
                      _MiniButton(icon: Icons.favorite, color: AppColors.like, onTap: () => respond(true)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: color, size: 22)),
        ),
      );
}
