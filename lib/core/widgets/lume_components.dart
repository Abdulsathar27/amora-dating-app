import 'package:flutter/material.dart';

import '../theme/lume_tokens.dart';
import 'animations/press_scale.dart';
import 'lume_button.dart';
import 'lume_icon.dart';
import 'lume_toggle.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

/// Shows a bundled asset (`assets/...`) or a network image, with a soft placeholder.
class LumePhoto extends StatelessWidget {
  const LumePhoto(this.source, {super.key, this.fit = BoxFit.cover, this.alignment = Alignment.center});

  final String? source;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(color: AppColors.lavenderSoft);
    final s = source;
    if (s == null || s.isEmpty) return placeholder;
    if (s.startsWith('assets/')) {
      return Image.asset(s, fit: fit, alignment: alignment, errorBuilder: (_, _, _) => placeholder);
    }
    return Image.network(
      s,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, p) => p == null ? child : placeholder,
    );
  }
}

/// The Lumé arch: a photo with a fully rounded top.
class ArchPhoto extends StatelessWidget {
  const ArchPhoto({
    super.key,
    required this.source,
    required this.width,
    required this.height,
    this.bottomRadius = 20,
    this.borderColor,
    this.borderWidth = 0,
    this.shadow,
    this.child,
  });

  final String? source;
  final double width;
  final double height;
  final double bottomRadius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadow;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final radius = AppRadius.arch(width, bottom: bottomRadius);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadow,
        border: borderColor == null ? null : Border.all(color: borderColor!, width: borderWidth),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(fit: StackFit.expand, children: [LumePhoto(source), ?child]),
      ),
    );
  }
}

/// Circular avatar.
class LumeAvatar extends StatelessWidget {
  const LumeAvatar(this.source, {super.key, this.size = 52, this.ringColor, this.ringWidth = 3});

  final String? source;
  final double size;
  final Color? ringColor;
  final double ringWidth;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: ringColor == null ? null : Border.all(color: ringColor!, width: ringWidth),
    ),
    child: ClipOval(child: LumePhoto(source)),
  );
}

enum TagVariant { normal, selected, lavender, blush }

/// Tag/Default · Selected · Lavender · Blush.
class LumeTag extends StatelessWidget {
  const LumeTag(this.label, {super.key, this.variant = TagVariant.normal, this.onTap, this.icon});

  final String label;
  final TagVariant variant;
  final VoidCallback? onTap;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      TagVariant.normal => (AppColors.surface, AppColors.ink, AppColors.line),
      TagVariant.selected => (AppColors.plum, AppColors.surface, AppColors.plum),
      TagVariant.lavender => (AppColors.lavenderSoft, AppColors.plum, AppColors.lavenderSoft),
      TagVariant.blush => (AppColors.blush, AppColors.coralDeep, AppColors.blush),
    };
    final tag = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[LumeIcon(icon!, size: 16, color: fg), AppGaps.w6],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: LumeText.labelM.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return tag;
    return Semantics(
      selected: variant == TagVariant.selected,
      button: true,
      child: PressScale(onTap: onTap, child: tag),
    );
  }
}

/// Lavender (or danger) info note: icon + body text.
class LumeNote extends StatelessWidget {
  const LumeNote(this.text, {super.key, this.icon = LumeIcons.info, this.danger = false});

  final String text;
  final String icon;
  final bool danger;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: danger ? AppColors.dangerSoft : AppColors.lavenderSoft,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LumeIcon(icon, size: 20, color: danger ? AppColors.danger : AppColors.plum),
        AppGaps.w10,
        Expanded(
          child: Text(text, style: LumeText.bodyM.copyWith(color: AppColors.ink)),
        ),
      ],
    ),
  );
}

/// White grouped card with soft elevation (rows separated by nothing, as in the design).
class LumeCard extends StatelessWidget {
  const LumeCard({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.color = AppColors.surface,
    this.radius = AppRadius.lg,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius), boxShadow: LumeShadows.soft),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

/// 40x40 lavender icon tile used at the start of rows.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.danger = false, this.size = 40});

  final String icon;
  final bool danger;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: danger ? AppColors.dangerSoft : AppColors.lavenderSoft,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    alignment: Alignment.center,
    child: LumeIcon(icon, size: 20, color: danger ? AppColors.danger : AppColors.plum),
  );
}

/// Settings / list row: optional icon tile, title, subtitle, and a trailing value,
/// chevron or toggle.
class LumeRow extends StatelessWidget {
  const LumeRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.value,
    this.onTap,
    this.toggle,
    this.onToggle,
    this.danger = false,
    this.chevron = true,
    this.trailing,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final String? icon;
  final String? value;
  final VoidCallback? onTap;
  final bool? toggle;
  final ValueChanged<bool>? onToggle;
  final bool danger;
  final bool chevron;
  final Widget? trailing;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          if (icon != null) ...[IconTile(icon!, danger: danger), AppGaps.w12],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: titleStyle ?? LumeText.titleS.copyWith(color: danger ? AppColors.danger : AppColors.ink),
                ),
                if (subtitle != null) ...[AppGaps.h2, Text(subtitle!, style: LumeText.bodyM)],
              ],
            ),
          ),
          if (value != null) ...[
            AppGaps.w8,
            Text(
              value!,
              style: LumeText.bodyM.copyWith(color: value == AppStrings.verified ? AppColors.success : AppColors.muted),
            ),
          ],
          ?trailing,
          if (toggle != null) ...[AppGaps.w12, LumeToggle(value: toggle!, onChanged: onToggle)],
          if (toggle == null && trailing == null && chevron && onTap != null && !danger) ...[
            AppGaps.w8,
            const LumeIcon(LumeIcons.next, size: 20, color: AppColors.muted),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      child: PressScale(onTap: onTap, scale: 0.98, child: row),
    );
  }
}

/// Screen header: back / close button, centered title, balance spacer or trailing action.
class LumeHeader extends StatelessWidget {
  const LumeHeader({super.key, this.title, this.onBack, this.close = false, this.trailing});

  final String? title;
  final VoidCallback? onBack;
  final bool close;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.headerHeight,
      child: Row(
        children: [
          if (onBack != null)
            LumeIconButton(
              close ? LumeIcons.close : LumeIcons.back,
              onPressed: onBack,
              tooltip: close ? AppStrings.close : AppStrings.back,
            )
          else
            AppGaps.w44,
          Expanded(
            child: Text(
              title ?? '',
              textAlign: TextAlign.center,
              style: LumeText.titleM,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing ?? AppGaps.w44,
        ],
      ),
    );
  }
}

/// Display title + optional muted subtitle used at the top of most screens.
class LumeTitle extends StatelessWidget {
  const LumeTitle(this.title, {super.key, this.subtitle, this.center = false});

  final String title;
  final String? subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
    children: [
      Text(title, style: LumeText.displayL, textAlign: center ? TextAlign.center : TextAlign.start),
      if (subtitle != null) ...[
        AppGaps.h8,
        Text(subtitle!, style: LumeText.bodyL, textAlign: center ? TextAlign.center : TextAlign.start),
      ],
    ],
  );
}

/// Standard full-page layout: header + scrollable body + pinned bottom actions.
class LumeScaffold extends StatelessWidget {
  const LumeScaffold({
    super.key,
    required this.body,
    this.header,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(24, 8, 24, 0),
    this.scroll = true,
    this.background = AppColors.background,
  });

  final Widget? header;
  final Widget body;
  final List<Widget>? bottom;
  final EdgeInsets padding;
  final bool scroll;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            if (header != null) Padding(padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 0), child: header),
            Expanded(
              child: scroll
                  ? SingleChildScrollView(padding: padding.copyWith(bottom: 24), child: body)
                  : Padding(padding: padding, child: body),
            ),
            if (bottom != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < bottom!.length; i++) ...[if (i > 0) AppGaps.h4, bottom![i]],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Empty / blocked / offline states: arch illustration, serif title, body, action.
class LumeEmptyState extends StatelessWidget {
  const LumeEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.icon,
    this.illustration,
    this.actionLabel,
    this.onAction,
    this.archColor = AppColors.lavenderSoft,
  });

  final String title;
  final String body;
  final String? icon;
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color archColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ??
                Container(
                  width: 180,
                  height: 220,
                  decoration: BoxDecoration(color: archColor, borderRadius: AppRadius.arch(180, bottom: 24)),
                  alignment: Alignment.center,
                  child: LumeIcon(
                    icon ?? LumeIcons.heart,
                    size: 56,
                    color: archColor == AppColors.blush ? AppColors.coralDeep : AppColors.plum,
                  ),
                ),
            AppGaps.h20,
            Text(title, textAlign: TextAlign.center, style: LumeText.displayL),
            AppGaps.h12,
            Text(body, textAlign: TextAlign.center, style: LumeText.bodyL),
            if (actionLabel != null) ...[
              AppGaps.h20,
              LumeButton(actionLabel!, variant: LumeButtonVariant.plum, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Segmented "Step n of 6" bar; filled segments animate in.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, this.total = 6});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.stepOf(step, total),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) AppGaps.w6,
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: i < step - 1 ? 1 : 0, end: i < step ? 1 : 0),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Label + 56px field + helper/error caption (Input/Default · Focus · Error).
class LumeField extends StatelessWidget {
  const LumeField({
    super.key,
    required this.label,
    this.initialValue,
    this.onChanged,
    this.helper,
    this.error,
    this.hint,
    this.keyboardType,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.fieldKey,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? helper;
  final String? error;
  final String? hint;
  final TextInputType? keyboardType;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final Key? fieldKey;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: c, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: LumeText.labelM),
        AppGaps.h8,
        TextFormField(
          key: fieldKey,
          initialValue: initialValue,
          onChanged: onChanged,
          autofocus: autofocus,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          style: LumeText.bodyL.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: LumeText.bodyL,
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: border(error != null ? AppColors.danger : AppColors.line, error != null ? 2 : 1.5),
            focusedBorder: border(error != null ? AppColors.danger : AppColors.plum, 2),
          ),
        ),
        if (error != null || helper != null) ...[
          AppGaps.h8,
          Text(
            error ?? helper!,
            style: LumeText.caption.copyWith(color: error != null ? AppColors.danger : AppColors.muted),
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet shell: 32px top radius, grabber, padding as in the design sheets.
Future<T?> showLumeSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.ink.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    sheetAnimationStyle: const AnimationStyle(duration: LumeMotion.sheet, reverseDuration: LumeMotion.pushExit),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppGaps.h10,
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(3)),
          ),
          Flexible(child: builder(ctx)),
        ],
      ),
    ),
  );
}

void showLumeSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: LumeText.bodyM.copyWith(color: AppColors.surface)),
        backgroundColor: AppColors.plum,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
}

/// Small rounded status chip (Verified / Approved / In review / Not approved).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.color = AppColors.success,
    this.background = AppColors.successSoft,
  });

  final String label;
  final String icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LumeIcon(icon, size: 16, color: color),
        AppGaps.w6,
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: LumeText.caption.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}
