import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lume_tokens.dart';
import '../../constants/app_colors.dart';

/// Like heart: icon scales 1 → 1.25 → 1 with a bouncy spring over 320ms.
/// Changing [trigger] replays the bounce.
class HeartBounce extends StatefulWidget {
  const HeartBounce({super.key, required this.child, required this.trigger});

  final Widget child;
  final int trigger;

  @override
  State<HeartBounce> createState() => _HeartBounceState();
}

class _HeartBounceState extends State<HeartBounce> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: LumeMotion.likeHeart);
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
  ]).animate(_controller);

  @override
  void didUpdateWidget(HeartBounce old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}

/// Repeating soft pulse (location rings, heart halo, recording button).
class Pulse extends StatefulWidget {
  const Pulse({
    super.key,
    required this.child,
    this.min = 0.94,
    this.max = 1.06,
    this.period = const Duration(milliseconds: 1600),
    this.repeat = true,
    this.count,
  });

  final Widget child;
  final double min;
  final double max;
  final Duration period;
  final bool repeat;

  /// Pulse exactly this many times, then stop (null = forever).
  final int? count;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    if (widget.count == null) {
      _controller.repeat(reverse: true);
      return;
    }
    for (var i = 0; i < widget.count! && mounted; i++) {
      await _controller.forward(from: 0);
      if (!mounted) return;
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (LumeMotion.reduceMotion(context)) return widget.child;
    return ScaleTransition(
      scale: Tween(begin: widget.min, end: widget.max).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// Horizontal shake used when the verification code is wrong.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.child, required this.trigger});

  final Widget child;
  final int trigger;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && widget.trigger > 0) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (_, child) {
      final t = _controller.value;
      final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
      return Transform.translate(offset: Offset(dx, 0), child: child);
    },
  );
}

/// Loading skeleton block with a moving sheen.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder:
        (_, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final x = -1.0 + _controller.value * 3;
            return LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x, 0),
              colors: const [AppColors.shimmerClear, AppColors.shimmerHighlight, AppColors.shimmerClear],
            ).createShader(rect);
          },
          child: child,
        ),
  );
}

/// Three bouncing dots ("typing…").
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder:
        (_, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7,
                transform: Matrix4.translationValues(0, -3 * math.max(0, math.sin((_controller.value - i * 0.18) * 2 * math.pi)), 0),
                decoration: BoxDecoration(color: i == 0 ? AppColors.plum : AppColors.plum.withValues(alpha: 0.45), shape: BoxShape.circle),
              ),
          ],
        ),
  );
}
