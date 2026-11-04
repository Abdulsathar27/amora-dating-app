import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/profile.dart';

/// Full profile, Hinge-style: photos interleaved with prompts.
class ProfileDetailView extends StatelessWidget {
  const ProfileDetailView({super.key, required this.profile, this.actions});

  final Profile profile;

  /// Optional bottom actions (like/pass from Likes You, etc).
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = profile;
    final blocks = <Widget>[];
    for (var i = 0; i < p.photos.length || i < p.prompts.length; i++) {
      if (i < p.photos.length) {
        blocks.add(ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(aspectRatio: 4 / 5, child: NetworkPhoto(p.photos[i])),
        ));
      }
      if (i < p.prompts.length) blocks.add(PromptCard(prompt: p.prompts[i]));
    }

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      bottomNavigationBar: actions == null ? null : SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: actions)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Text('${p.name}, ${p.age}', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (p.isVerified) const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.verified, color: AppColors.superLike),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Fact(Icons.favorite_border, p.intent.label),
            if (p.jobTitle != null) _Fact(Icons.work_outline, p.jobTitle!),
            if (p.school != null) _Fact(Icons.school_outlined, p.school!),
            if (p.city != null) _Fact(Icons.home_outlined, p.city!),
            if (p.heightCm != null) _Fact(Icons.height, '${p.heightCm} cm'),
            if (p.distanceKm != null) _Fact(Icons.location_on_outlined, '${p.distanceKm!.toStringAsFixed(0)} km away'),
          ]),
          if (p.bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(p.bio, style: t.bodyLarge),
          ],
          const SizedBox(height: 16),
          for (final b in blocks) Padding(padding: const EdgeInsets.only(bottom: 16), child: b),
          if (p.interests.isNotEmpty) ...[
            Text('Interests', style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final i in p.interests) Chip(label: Text(i))]),
          ],
        ],
      ),
    );
  }
}

class PromptCard extends StatelessWidget {
  const PromptCard({super.key, required this.prompt});
  final ProfilePrompt prompt;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prompt.question, style: t.labelLarge),
            const SizedBox(height: 8),
            Text(prompt.answer, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Chip(avatar: Icon(icon, size: 18), label: Text(text));
}
