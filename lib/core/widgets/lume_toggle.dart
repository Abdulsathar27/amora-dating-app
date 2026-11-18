import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/lume_tokens.dart';
import '../constants/app_colors.dart';

/// 52x32 pill switch. Knob slide + track colour are driven by an AnimationController.
class LumeToggle extends StatefulWidget {
  const LumeToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<LumeToggle> createState() => _LumeToggleState();
}

class _LumeToggleState extends State<LumeToggle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: widget.value ? 1 : 0,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeInBack,
  );

  @override
  void didUpdateWidget(LumeToggle old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) widget.value ? _controller.forward() : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: widget.value,
      child: GestureDetector(
        onTap: widget.onChanged == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onChanged!(!widget.value);
              },
        child: AnimatedBuilder(
          animation: _t,
          builder: (_, _) => Container(
            width: 52,
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Color.lerp(AppColors.line, AppColors.plum, _controller.value),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Align(
              alignment: Alignment(-1 + 2 * _t.value, 0),
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: LumeShadows.soft,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
