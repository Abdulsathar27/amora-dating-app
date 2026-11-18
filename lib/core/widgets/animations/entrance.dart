import 'package:flutter/material.dart';

import '../../theme/lume_tokens.dart';

/// Staggered entrance for screen content: each child fades in and rises 16px,
/// driven by one AnimationController with an Interval per child.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 0,
    this.duration = const Duration(milliseconds: 600),
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final Duration duration;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LumeMotion.reduceMotion(context)) {
      _controller.duration = LumeMotion.reduced;
    }
    if (!_controller.isAnimating && _controller.value == 0) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.children.length;
    final reduce = LumeMotion.reduceMotion(context);
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++) ...[
          if (i > 0 && widget.spacing > 0) SizedBox(height: widget.spacing),
          _Item(
            animation: CurvedAnimation(
              parent: _controller,
              curve: Interval((i / (n + 2)).clamp(0, 0.7), ((i + 3) / (n + 2)).clamp(0.3, 1), curve: LumeMotion.gentle),
            ),
            offset: reduce ? 0 : 16,
            child: widget.children[i],
          ),
        ],
      ],
    );
  }
}

/// Single fade + rise for one widget.
class FadeRise extends StatefulWidget {
  const FadeRise({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 16,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  State<FadeRise> createState() => _FadeRiseState();
}

class _FadeRiseState extends State<FadeRise> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Item(
    animation: CurvedAnimation(parent: _controller, curve: LumeMotion.gentle),
    offset: LumeMotion.reduceMotion(context) ? 0 : widget.offset,
    child: widget.child,
  );
}

class _Item extends AnimatedWidget {
  const _Item({required Animation<double> animation, required this.child, required this.offset})
    : super(listenable: animation);

  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(offset: Offset(0, (1 - t) * offset), child: child),
    );
  }
}
