import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/match.dart';

/// "It's a Match!" overlay shown after a mutual like.
class MatchDialog extends StatelessWidget {
  const MatchDialog({super.key, required this.match, required this.onMessage, this.myPhoto});

  final Match match;
  final String? myPhoto;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (r) => AppColors.brandGradient.createShader(r),
            child: const Text(
              "It's a Match!",
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You and ${match.profile.name} like each other.',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(angle: -0.12, child: Avatar(myPhoto, size: 120, ring: true)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.favorite, color: AppColors.primary, size: 36),
              ),
              Transform.rotate(angle: 0.12, child: Avatar(match.profile.mainPhoto, size: 120, ring: true)),
            ],
          ),
          if (match.expiresAt != null) ...[
            const SizedBox(height: 16),
            const Text('Say hi within 24 hours before the match expires.', style: TextStyle(color: Colors.white70)),
          ],
          const SizedBox(height: 28),
          GradientButton(label: 'Send a message', onPressed: onMessage),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep swiping'),
          ),
        ],
      ),
    );
  }
}
