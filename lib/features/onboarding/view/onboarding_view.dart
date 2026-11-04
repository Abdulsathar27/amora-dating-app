import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/profile.dart';
import '../../auth/view_model/auth_bloc.dart';
import '../view_model/onboarding_cubit.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.read<AuthBloc>().state.user?.name ?? '';
    return BlocProvider(
      create: (_) => OnboardingCubit(sl(), sl(), initialName: name),
      child: BlocConsumer<OnboardingCubit, OnboardingState>(
        listenWhen: (a, b) => a.isDone != b.isDone || (b.error != null && a.error != b.error),
        listener: (context, s) {
          if (s.isDone) context.read<AuthBloc>().add(const AuthOnboardingCompleted());
          if (s.error != null) showSnack(context, s.error!);
        },
        builder: (context, s) {
          final cubit = context.read<OnboardingCubit>();
          return Scaffold(
            appBar: AppBar(
              leading: s.step.index == 0 ? null : BackButton(onPressed: cubit.back),
              title: LinearProgressIndicator(value: s.progress, borderRadius: BorderRadius.circular(4)),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: switch (s.step) {
                          OnboardingStep.basics => _BasicsStep(s),
                          OnboardingStep.gender => _GenderStep(s),
                          OnboardingStep.intent => _IntentStep(s),
                          OnboardingStep.about => _AboutStep(s),
                          OnboardingStep.prompts => _PromptStep(s),
                          OnboardingStep.interests => _InterestsStep(s),
                        },
                      ),
                    ),
                    GradientButton(
                      label: s.isLast ? 'Start matching' : 'Continue',
                      loading: s.isSubmitting,
                      onPressed: s.canContinue ? cubit.next : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader(this.title, [this.subtitle]);
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle!, style: t.bodyLarge)],
        ],
      ),
    );
  }
}

class _BasicsStep extends StatelessWidget {
  const _BasicsStep(this.s);
  final OnboardingState s;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader("Let's get you started", 'This is how you will appear on Amora.'),
        TextFormField(
          initialValue: s.name,
          onChanged: cubit.nameChanged,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'First name'),
        ),
        const SizedBox(height: 24),
        Text('Age: ${s.age}', style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: s.age.toDouble(),
          min: 18,
          max: 70,
          divisions: 52,
          label: '${s.age}',
          onChanged: (v) => cubit.ageChanged(v.round()),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: s.jobTitle,
          onChanged: cubit.jobChanged,
          decoration: const InputDecoration(labelText: 'Job title (optional)'),
        ),
      ],
    );
  }
}

class _GenderStep extends StatelessWidget {
  const _GenderStep(this.s);
  final OnboardingState s;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeader('I am a'),
        for (final g in Gender.values)
          _OptionTile(label: g.label, selected: s.gender == g, onTap: () => cubit.genderSelected(g)),
        const SizedBox(height: 24),
        Text('Show me', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final i in InterestedIn.values)
              ChoiceChip(
                label: Text(i.label),
                selected: s.interestedIn == i,
                onSelected: (_) => cubit.interestedInSelected(i),
              ),
          ],
        ),
      ],
    );
  }
}

class _IntentStep extends StatelessWidget {
  const _IntentStep(this.s);
  final OnboardingState s;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return Column(
      children: [
        const _StepHeader('What are you looking for?', 'We show this on your profile so intentions are clear.'),
        for (final i in RelationshipIntent.values)
          _OptionTile(label: i.label, selected: s.intent == i, onTap: () => cubit.intentSelected(i)),
      ],
    );
  }
}

class _AboutStep extends StatelessWidget {
  const _AboutStep(this.s);
  final OnboardingState s;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepHeader('About you', 'A short bio helps start conversations.'),
        TextFormField(
          initialValue: s.bio,
          onChanged: context.read<OnboardingCubit>().bioChanged,
          maxLines: 5,
          maxLength: 300,
          decoration: const InputDecoration(hintText: 'Weekend hiker, filter-coffee loyalist, terrible at karaoke...'),
        ),
      ],
    );
  }
}

class _PromptStep extends StatelessWidget {
  const _PromptStep(this.s);
  final OnboardingState s;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return Column(
      children: [
        const _StepHeader('Answer a prompt', 'Prompts give people something easy to reply to.'),
        DropdownButtonFormField<String>(
          initialValue: s.promptQuestion,
          isExpanded: true,
          items: [for (final q in kPromptQuestions) DropdownMenuItem(value: q, child: Text(q))],
          onChanged: (q) => q == null ? null : cubit.promptQuestionSelected(q),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: s.promptAnswer,
          onChanged: cubit.promptAnswerChanged,
          maxLines: 3,
          maxLength: 150,
          decoration: const InputDecoration(hintText: 'Your answer'),
        ),
      ],
    );
  }
}

class _InterestsStep extends StatelessWidget {
  const _InterestsStep(this.s);
  final OnboardingState s;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return Column(
      children: [
        _StepHeader('Your interests', 'Pick at least 3 (${s.interests.length} selected).'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final i in kInterestOptions)
              FilterChip(label: Text(i), selected: s.interests.contains(i), onSelected: (_) => cubit.interestToggled(i)),
          ],
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? scheme.primary.withValues(alpha: 0.12) : scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? scheme.primary : Colors.transparent, width: 2),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: selected ? Icon(Icons.check_circle, color: scheme.primary) : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
