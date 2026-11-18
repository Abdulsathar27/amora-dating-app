import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/lume_tokens.dart';

/// Lumé tap feedback: scale to 0.96 over 120ms ease-out, with a light haptic.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap, this.scale = LumeMotion.tapScale, this.haptic = true});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: LumeMotion.tap, reverseDuration: LumeMotion.tap);
  late final Animation<double> _scale = Tween(begin: 1.0, end: widget.scale).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) => _controller.forward();

  void _up([Object? _]) => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? _down : null,
      onTapUp: enabled ? _up : null,
      onTapCancel: enabled ? _up : null,
      onTap:
          enabled
              ? () {
                if (widget.haptic) HapticFeedback.lightImpact();
                widget.onTap!();
              }
              : null,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
