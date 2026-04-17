import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';

enum UButtonType { normal, success, warning, error, info }

class UButton extends StatefulWidget {
  const UButton({
    super.key,
    this.child = const Text('UButton'),
    this.type = UButtonType.normal,
    this.color,
    this.padding,
    this.borderRadius,
    this.border,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onSecondaryTapUp,
    this.onSecondaryTapDown,
    this.onSecondaryTapCancel,
  });

  final EdgeInsetsGeometry? padding;
  final Widget child;
  final Color? color;
  final UButtonType type;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final GestureTapCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCallback? onTapCancel;
  final GestureTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onSecondaryTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final GestureTapDownCallback? onSecondaryTapDown;
  final GestureTapCallback? onSecondaryTapCancel;

  @override
  State<UButton> createState() => _UButtonState();
}

class _UButtonState extends State<UButton> {
  bool _tapping = false;

  Color _getColor(UThemeData theme) {
    if (widget.color != null) return widget.color!;
    switch (widget.type) {
      case UButtonType.normal:
        return theme.primary;
      case UButtonType.success:
        return const Color(0xFF22C55E);
      case UButtonType.warning:
        return const Color(0xFFF59E0B);
      case UButtonType.error:
        return theme.error;
      case UButtonType.info:
        return theme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    final color = _getColor(theme);
    final childColor = color.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    final padding =
        widget.padding ??
        EdgeInsets.symmetric(
          horizontal: theme.spacingMedium,
          vertical: theme.spacingSmall,
        );
    final borderRadius =
        widget.borderRadius ?? BorderRadius.circular(theme.borderRadiusMedium);

    return GestureDetector(
      onPanDown: (_) => setState(() => _tapping = true),
      onPanEnd: (_) => setState(() => _tapping = false),
      onPanCancel: () => setState(() => _tapping = false),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: widget.onTapDown,
      onTapUp: widget.onTapUp,
      onTapCancel: widget.onTapCancel,
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      onSecondaryTap: widget.onSecondaryTap,
      onSecondaryTapUp: widget.onSecondaryTapUp,
      onSecondaryTapDown: widget.onSecondaryTapDown,
      onSecondaryTapCancel: widget.onSecondaryTapCancel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: DefaultTextStyle(
          style: TextStyle(color: childColor),
          child: IconTheme(
            data: IconThemeData(color: childColor),
            child: AnimatedContainer(
              padding: padding,
              decoration: BoxDecoration(
                color: _tinting(color),
                borderRadius: borderRadius,
                border: widget.border,
              ),
              duration: theme.animationDuration,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  Color _tinting(Color color) {
    if (!_tapping) return color;
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }
}
