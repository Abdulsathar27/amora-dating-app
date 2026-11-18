import 'package:flutter/material.dart';

import '../theme/lume_tokens.dart';
import 'animations/press_scale.dart';
import 'lume_icon.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

enum LumeButtonVariant { primary, plum, secondary, ghost, danger }

/// Button/Primary · Plum · Secondary · Ghost · Danger · Disabled from the Components page.
class LumeButton extends StatelessWidget {
  const LumeButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = LumeButtonVariant.primary,
    this.loading = false,
    this.height = AppSizes.buttonHeight,
    this.icon,
    this.ghostColor = AppColors.plum,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final LumeButtonVariant variant;
  final bool loading;
  final double height;
  final String? icon;

  /// Text colour for the ghost variant (white on the plum Match screen).
  final Color ghostColor;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !loading;
    final (bg, fg, border, shadow) =
        disabled
            ? (AppColors.line, AppColors.muted, null, false)
            : switch (variant) {
              LumeButtonVariant.primary => (AppColors.coral, AppColors.ink, null, true),
              LumeButtonVariant.plum => (AppColors.plum, AppColors.surface, null, false),
              LumeButtonVariant.secondary => (AppColors.surface, AppColors.plum, AppColors.line, false),
              LumeButtonVariant.ghost => (Colors.transparent, ghostColor, null, false),
              LumeButtonVariant.danger => (AppColors.dangerSoft, AppColors.danger, null, false),
            };

    final content =
        loading
            ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[LumeIcon(icon!, size: 20, color: fg), AppGaps.w8],
                Flexible(
                  child: Text(label, style: LumeText.labelL.copyWith(color: fg), overflow: TextOverflow.ellipsis),
                ),
              ],
            );

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: PressScale(
        onTap: loading ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(height / 2),
            border: border == null ? null : Border.all(color: border, width: 1.5),
            boxShadow: shadow ? LumeShadows.soft : null,
          ),
          alignment: Alignment.center,
          child: ExcludeSemantics(child: content),
        ),
      ),
    );
  }
}

/// Round icon button (back, close, sliders, more…). 44x44 hit target.
class LumeIconButton extends StatelessWidget {
  const LumeIconButton(
    this.icon, {
    super.key,
    required this.onPressed,
    this.size = AppSizes.iconButton,
    this.iconSize = AppSizes.iconButtonIcon,
    this.color = AppColors.plum,
    this.background,
    this.bordered = false,
    this.tooltip,
  });

  final String icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color color;
  final Color? background;
  final bool bordered;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip ?? icon,
      child: PressScale(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: bordered ? Border.all(color: AppColors.line) : null,
          ),
          alignment: Alignment.center,
          child: LumeIcon(icon, size: iconSize, color: color),
        ),
      ),
    );
  }
}
