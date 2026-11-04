import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Network image with a neutral placeholder and error fallback.
class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto(this.url, {super.key, this.fit = BoxFit.cover});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.person, size: 48)),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(
      url!,
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.url, {super.key, this.size = 52, this.ring = false});

  final String? url;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final img = ClipOval(child: SizedBox.square(dimension: size, child: NetworkPhoto(url)));
    if (!ring) return img;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).scaffoldBackgroundColor),
        child: img,
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.title, this.subtitle, this.action});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(title, style: t.titleLarge, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: t.bodyMedium, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : AppColors.brandGradient,
        color: onPressed == null ? Colors.grey.shade400 : null,
        borderRadius: BorderRadius.circular(26),
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}
