import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/profile.dart';
import '../../onboarding/view_model/onboarding_cubit.dart' show kInterestOptions, kPromptQuestions;
import '../view_model/edit_profile_cubit.dart';
import '../view_model/profile_bloc.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (a, b) => a.savedAt != b.savedAt || (b.error != null && a.error != b.error),
      listener: (context, s) {
        if (s.error != null) return showSnack(context, s.error!);
        Navigator.of(context).pop();
      },
      child: BlocBuilder<EditProfileCubit, EditProfileState>(
        builder: (context, s) {
          final cubit = context.read<EditProfileCubit>();
          final d = s.draft;
          final saving = context.select<ProfileBloc, bool>((b) => b.state.status == ProfileStatus.saving);
          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit profile'),
              actions: [
                TextButton(
                  onPressed: s.isDirty && !saving
                      ? () => context.read<ProfileBloc>().add(ProfileSaved(s.changes))
                      : null,
                  child: saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _Header('Photos', 'Add up to 6. The first one is your main photo.'),
                _PhotoGrid(photos: d.photos),
                const _Header('About me'),
                TextFormField(
                  initialValue: d.bio,
                  onChanged: cubit.bioChanged,
                  maxLines: 4,
                  maxLength: 300,
                ),
                const _Header('Prompts', 'Up to 3 – these are the easiest conversation starters.'),
                for (var i = 0; i < d.prompts.length; i++)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 4, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: Text(d.prompts[i].question, style: const TextStyle(fontWeight: FontWeight.bold))),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => cubit.promptRemoved(i)),
                          ]),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: TextFormField(
                              key: ValueKey('prompt-${d.prompts[i].question}'),
                              initialValue: d.prompts[i].answer,
                              onChanged: (v) => cubit.promptAnswerChanged(i, v),
                              maxLength: 150,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (d.prompts.length < 3)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add a prompt'),
                    onPressed: () => _pickPrompt(context, d),
                  ),
                const _Header('Looking for'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final i in RelationshipIntent.values)
                    ChoiceChip(label: Text(i.label), selected: d.intent == i, onSelected: (_) => cubit.intentChanged(i)),
                ]),
                const _Header('Basics'),
                TextFormField(initialValue: d.jobTitle, onChanged: cubit.jobChanged, decoration: const InputDecoration(labelText: 'Job title')),
                const SizedBox(height: 12),
                TextFormField(initialValue: d.school, onChanged: cubit.schoolChanged, decoration: const InputDecoration(labelText: 'School')),
                const SizedBox(height: 12),
                TextFormField(initialValue: d.city, onChanged: cubit.cityChanged, decoration: const InputDecoration(labelText: 'City')),
                const _Header('Interests'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final i in kInterestOptions)
                    FilterChip(label: Text(i), selected: d.interests.contains(i), onSelected: (_) => cubit.interestToggled(i)),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickPrompt(BuildContext context, Profile d) async {
    final used = d.prompts.map((p) => p.question).toSet();
    final q = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          for (final q in kPromptQuestions.where((q) => !used.contains(q)))
            ListTile(title: Text(q), onTap: () => Navigator.pop(ctx, q)),
        ],
      ),
    );
    if (q != null && context.mounted) context.read<EditProfileCubit>().promptAdded(q);
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title, [this.subtitle]);
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (subtitle != null) Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.photos});
  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditProfileCubit>();
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.75,
      children: [
        for (var i = 0; i < 6; i++)
          if (i < photos.length)
            Stack(fit: StackFit.expand, children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: NetworkPhoto(photos[i])),
              Positioned(
                right: 4,
                top: 4,
                child: InkWell(
                  onTap: () => cubit.photoRemoved(i),
                  child: const CircleAvatar(radius: 12, child: Icon(Icons.close, size: 14)),
                ),
              ),
            ])
          else
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _addPhoto(context),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 2),
                ),
                child: const Center(child: Icon(Icons.add_a_photo_outlined)),
              ),
            ),
      ],
    );
  }

  /// Until the backend has an upload endpoint (multipart via Dio FormData),
  /// photos are added by URL.
  Future<void> _addPhoto(BuildContext context) async {
    var url = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add photo'),
        content: TextField(
          autofocus: true,
          onChanged: (v) => url = v,
          decoration: const InputDecoration(hintText: 'https://...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<EditProfileCubit>().photoAdded(url);
  }
}
