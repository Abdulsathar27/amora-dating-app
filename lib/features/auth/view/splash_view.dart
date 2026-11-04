import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.brandGradient),
        child: Center(child: AmoraLogo(size: 44, light: true)),
      ),
    );
  }
}

class AmoraLogo extends StatelessWidget {
  const AmoraLogo({super.key, this.size = 28, this.light = false});

  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite_rounded, color: color, size: size),
        const SizedBox(width: 6),
        Text(
          'amora',
          style: TextStyle(color: color, fontSize: size * 0.9, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
      ],
    );
  }
}
