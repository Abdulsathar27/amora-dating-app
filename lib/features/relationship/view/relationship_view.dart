import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/value_cubit.dart';
import '../../../data/models/match.dart';
import '../../../data/models/relationship.dart';
import '../../auth/view_model/auth_bloc.dart';
import '../../matches/view_model/matches_bloc.dart';
import '../../profile/view_model/profile_bloc.dart';
import '../view_model/relationship_bloc.dart';

/// "Us" tab – from match to couple.
class RelationshipView extends StatelessWidget {
  const RelationshipView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RelationshipBloc, RelationshipState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, s) => showSnack(context, s.error!),
      builder: (context, s) {
        final bloc = context.read<RelationshipBloc>();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Us'),
            actions: [
              if (s.isActive)
                PopupMenuButton<String>(
                  onSelected: (_) => _confirmEnd(context),
                  itemBuilder: (_) => const [PopupMenuItem(value: 'end', child: Text('End relationship'))],
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => bloc.add(const RelationshipLoaded()),
            child: switch (s.status) {
              RelationshipViewStatus.loading => const LoadingView(),
              RelationshipViewStatus.failure =>
                ErrorView(message: s.error ?? 'Error', onRetry: () => bloc.add(const RelationshipLoaded())),
              RelationshipViewStatus.ready => switch (s.relationship.status) {
                  RelationshipStatus.none => const _SinglePrompt(),
                  RelationshipStatus.pendingSent => _Pending(state: s, incoming: false),
                  RelationshipStatus.pendingReceived => _Pending(state: s, incoming: true),
                  RelationshipStatus.active => _CoupleDashboard(state: s),
                },
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmEnd(BuildContext context) async {
    final bloc = context.read<RelationshipBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End relationship?'),
        content: const Text('Your shared space will be closed for both of you.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('End', style: TextStyle(color: AppColors.nope))),
        ],
      ),
    );
    if (ok == true) bloc.add(const RelationshipEnded());
  }
}

// ---------------- No relationship yet ----------------
class _SinglePrompt extends StatelessWidget {
  const _SinglePrompt();

  @override
  Widget build(BuildContext context) {
    final matches = context.select<MatchesBloc, List<Match>>((b) => b.state.conversations);
    final busy = context.select<RelationshipBloc, bool>((b) => b.state.isBusy);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.favorite, size: 72, color: AppColors.primary),
        const SizedBox(height: 12),
        Text('Found someone special?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Ask a match to be your partner. Together you get a private space for date plans, memories, daily mood check-ins and your anniversary countdown.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (matches.isEmpty)
          const Text('Start a conversation with a match first.', textAlign: TextAlign.center)
        else
          for (final m in matches)
            Card(
              child: ListTile(
                leading: Avatar(m.profile.mainPhoto, size: 44),
                title: Text(m.profile.name),
                subtitle: Text(m.profile.intent.label),
                trailing: FilledButton.tonal(
                  onPressed: busy ? null : () => context.read<RelationshipBloc>().add(PartnerRequestSent(m.id)),
                  child: const Text('Ask 💞'),
                ),
              ),
            ),
      ],
    );
  }
}

class _Pending extends StatelessWidget {
  const _Pending({required this.state, required this.incoming});
  final RelationshipState state;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    final partner = state.relationship.partner;
    final bloc = context.read<RelationshipBloc>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(child: Avatar(partner?.mainPhoto, size: 120, ring: true)),
        const SizedBox(height: 16),
        Text(
          incoming ? '${partner?.name} wants to make it official!' : 'Waiting for ${partner?.name} to accept…',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        if (incoming) ...[
          GradientButton(label: 'Accept 💞', loading: state.isBusy, onPressed: () => bloc.add(const PartnerRequestAnswered(accept: true))),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => bloc.add(const PartnerRequestAnswered(accept: false)), child: const Text('Decline')),
        ] else
          OutlinedButton.icon(
            onPressed: () => bloc.add(const RelationshipLoaded()),
            icon: const Icon(Icons.refresh),
            label: const Text('Check again'),
          ),
      ],
    );
  }
}

// ---------------- Couple dashboard ----------------
class _CoupleDashboard extends StatelessWidget {
  const _CoupleDashboard({required this.state});
  final RelationshipState state;

  @override
  Widget build(BuildContext context) {
    final rel = state.relationship;
    final myPhoto = context.select<ProfileBloc, String?>((b) => b.state.profile?.mainPhoto);
    final myId = context.read<AuthBloc>().state.user?.id;
    final t = Theme.of(context).textTheme;
    final anniversary = rel.nextAnniversary;
    final partnerMood = state.checkIns.where((c) => c.userId != myId).firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(24)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Avatar(myPhoto, size: 72),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.favorite, color: Colors.white, size: 32)),
              Avatar(rel.partner?.mainPhoto, size: 72),
            ]),
            const SizedBox(height: 12),
            Text('You & ${rel.partner?.name ?? ''}', style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('${rel.daysTogether} days together', style: t.headlineSmall?.copyWith(color: Colors.white)),
            if (anniversary != null)
              Text(
                'Anniversary in ${anniversary.difference(DateTime.now()).inDays} days · ${DateFormat.MMMd().format(anniversary)}',
                style: const TextStyle(color: Colors.white70),
              ),
          ]),
        ),
        // Mood
        _Section(
          title: 'How are you feeling today?',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final m in Mood.values)
                  _MoodButton(mood: m, selected: state.todaysCheckIn?.mood == m),
              ],
            ),
            if (partnerMood != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${rel.partner?.name} is feeling ${partnerMood.mood.emoji} ${partnerMood.mood.value}'),
              ),
          ]),
        ),
        // Date plans
        _Section(
          title: 'Upcoming dates',
          action: IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _addDatePlan(context)),
          child: state.upcomingPlans.isEmpty
              ? const Text('No dates planned. Add one!')
              : Column(children: [
                  for (final p in state.upcomingPlans)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.event)),
                      title: Text(p.title),
                      subtitle: Text([DateFormat('EEE, MMM d · h:mm a').format(p.scheduledAt.toLocal()), if (p.place != null && p.place!.isNotEmpty) p.place].join('\n')),
                      isThreeLine: p.place != null && p.place!.isNotEmpty,
                      trailing: IconButton(
                        tooltip: 'Mark done',
                        icon: const Icon(Icons.check_circle_outline, color: AppColors.like),
                        onPressed: () => context.read<RelationshipBloc>().add(DatePlanStatusChanged(p, DatePlanStatus.done)),
                      ),
                    ),
                ]),
        ),
        // Memories
        _Section(
          title: 'Our memories',
          action: IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _addMemory(context)),
          child: state.memories.isEmpty
              ? const Text('Save your first memory together.')
              : Column(children: [
                  for (final m in state.memories)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.photo_album_outlined)),
                      title: Text(m.title),
                      subtitle: Text([DateFormat.yMMMd().format(m.date.toLocal()), if (m.note != null && m.note!.isNotEmpty) m.note!].join(' · ')),
                    ),
                ]),
        ),
      ],
    );
  }

  Future<void> _addDatePlan(BuildContext context) async {
    final bloc = context.read<RelationshipBloc>();
    final draft = ValueCubit<({String title, String place, DateTime when})>(
      (title: '', place: '', when: DateTime.now().add(const Duration(days: 1))),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(value: draft, child: const _DatePlanDialog()),
    );
    final d = draft.state;
    if (ok == true && d.title.trim().isNotEmpty) {
      bloc.add(DatePlanAdded(title: d.title.trim(), scheduledAt: d.when, place: d.place.trim()));
    }
    await draft.close();
  }

  Future<void> _addMemory(BuildContext context) async {
    final bloc = context.read<RelationshipBloc>();
    var title = '';
    var note = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New memory'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(autofocus: true, onChanged: (v) => title = v, decoration: const InputDecoration(hintText: 'Our first trip to Munnar')),
          const SizedBox(height: 10),
          TextField(onChanged: (v) => note = v, maxLines: 3, decoration: const InputDecoration(hintText: 'What made it special?')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && title.trim().isNotEmpty) {
      bloc.add(MemoryAdded(title: title.trim(), date: DateTime.now(), note: note.trim()));
    }
  }
}

class _DatePlanDialog extends StatelessWidget {
  const _DatePlanDialog();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ValueCubit<({String title, String place, DateTime when})>>();
    return BlocBuilder<ValueCubit<({String title, String place, DateTime when})>, ({String title, String place, DateTime when})>(
      builder: (context, d) => AlertDialog(
        title: const Text('Plan a date'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            autofocus: true,
            onChanged: (v) => cubit.set((title: v, place: d.place, when: d.when)),
            decoration: const InputDecoration(hintText: 'Dinner at the beach'),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => cubit.set((title: d.title, place: v, when: d.when)),
            decoration: const InputDecoration(hintText: 'Place (optional)'),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month),
            title: Text(DateFormat('EEE, MMM d · h:mm a').format(d.when)),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: d.when,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date == null || !context.mounted) return;
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(d.when));
              final at = DateTime(date.year, date.month, date.day, time?.hour ?? 19, time?.minute ?? 0);
              cubit.set((title: cubit.state.title, place: cubit.state.place, when: at));
            },
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: d.title.trim().isEmpty ? null : () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({required this.mood, required this.selected});
  final Mood mood;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () => context.read<RelationshipBloc>().add(MoodCheckedIn(mood)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
        ),
        child: Text(mood.emoji, style: TextStyle(fontSize: selected ? 34 : 28)),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.action});
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(top: 16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
              if (action != null) action! else const SizedBox(height: 48),
            ]),
            Padding(padding: const EdgeInsets.only(right: 8), child: child),
          ]),
        ),
      );
}
