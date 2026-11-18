import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Voice waveform. Bars before [progress] use [activeColor]. When [playing] is
/// true an AnimationController sweeps the progress and gently breathes the bars.
class Waveform extends StatefulWidget {
  const Waveform({
    super.key,
    required this.heights,
    this.progress = 0.5,
    this.playing = false,
    this.activeColor = AppColors.coral,
    this.idleColor = AppColors.line,
    this.barWidth = 3,
    this.gap = 3,
    this.duration = const Duration(seconds: 15),
  });

  /// Bar heights in logical pixels (taken from the design's bars).
  final List<double> heights;
  final double progress;
  final bool playing;
  final Color activeColor;
  final Color idleColor;
  final double barWidth;
  final double gap;
  final Duration duration;

  static const intro = <double>[8.0, 19, 30, 16, 35, 24, 11, 27, 38, 19, 14, 33, 22, 8, 24, 35, 16, 27, 11, 22, 33, 14, 19, 30, 8, 16, 27, 22, 11, 19];
  static const priya = <double>[7.0, 17, 27, 15, 32, 22, 10, 24, 34, 17, 12, 29, 19, 7, 22, 32, 15, 24, 10, 19, 29, 12, 17, 27, 7, 15];
  static const chip = <double>[5.0, 11, 17, 9, 20, 14, 6, 16, 22, 11, 8];

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    _controller.value = widget.progress;
    if (widget.playing) _controller.forward();
  }

  @override
  void didUpdateWidget(Waveform old) {
    super.didUpdateWidget(old);
    if (widget.playing && !old.playing) {
      _controller.forward(from: _controller.isCompleted ? 0 : _controller.value);
    } else if (!widget.playing && old.playing) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = widget.heights.reduce((a, b) => a > b ? a : b);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final p = _controller.value;
        final n = widget.heights.length;
        return SizedBox(
          height: maxH,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) SizedBox(width: widget.gap),
                Container(
                  width: widget.barWidth,
                  height: widget.heights[i] * (widget.playing && i / n <= p && i / n > p - 0.12 ? 1.12 : 1),
                  decoration: BoxDecoration(color: i / n < p ? widget.activeColor : widget.idleColor, borderRadius: BorderRadius.circular(1)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
