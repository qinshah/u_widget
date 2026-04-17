import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';

enum UButtonVariant {
  filled,
  outlined,
  text,
  ghost,
}

enum UButtonSize {
  small,
  medium,
  large,
}

class UButton extends StatefulWidget {
  const UButton({
    super.key,
    this.child = const Text('Button'),
    this.variant = UButtonVariant.filled,
    this.size = UButtonSize.medium,
    this.color,
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
    this.enabled = true,
    this.fullWidth = false,
  });

  final Widget child;
  final UButtonVariant variant;
  final UButtonSize size;
  final Color? color;
  final bool enabled;
  final bool fullWidth;
  
  // Gesture callbacks
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
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    final effectiveColor = widget.color ?? theme.primary;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onPanDown: (_) => setState(() => _isPressed = true),
        onPanEnd: (_) => setState(() => _isPressed = false),
        onPanCancel: () => setState(() => _isPressed = false),
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: widget.enabled ? widget.onTapDown : null,
        onTapUp: widget.enabled ? widget.onTapUp : null,
        onTapCancel: widget.enabled ? widget.onTapCancel : null,
        onDoubleTap: widget.enabled ? widget.onDoubleTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        onSecondaryTap: widget.enabled ? widget.onSecondaryTap : null,
        onSecondaryTapUp: widget.enabled ? widget.onSecondaryTapUp : null,
        onSecondaryTapDown: widget.enabled ? widget.onSecondaryTapDown : null,
        onSecondaryTapCancel: widget.enabled ? widget.onSecondaryTapCancel : null,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: _buildButtonContent(theme, effectiveColor),
        ),
      ),
    );
  }

  Widget _buildButtonContent(UThemeData theme, Color color) {
    final isDisabled = !widget.enabled;
    final isInteractive = !isDisabled && (_isHovering || _isPressed);
    
    final buttonStyle = _getButtonStyle(theme, color, isDisabled, isInteractive);
    final textStyle = _getTextStyle(theme, color, isDisabled);
    final padding = _getPadding(theme);

    return AnimatedContainer(
      duration: theme.animationDuration,
      padding: padding,
      decoration: buttonStyle,
      child: DefaultTextStyle(
        style: textStyle,
        child: IconTheme(
          data: IconThemeData(
            color: _getTextColor(color, isDisabled),
            size: _getIconSize(),
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }

  BoxDecoration _getButtonStyle(UThemeData theme, Color color, bool isDisabled, bool isInteractive) {
    final baseStyle = BoxDecoration(
      borderRadius: BorderRadius.circular(theme.borderRadiusMedium),
    );

    switch (widget.variant) {
      case UButtonVariant.filled:
        return baseStyle.copyWith(
          color: _getFilledColor(color, isDisabled, isInteractive),
        );
      
      case UButtonVariant.outlined:
        return baseStyle.copyWith(
          color: Colors.transparent,
          border: Border.all(
            color: _getOutlineColor(color, isDisabled),
            width: 1,
          ),
        );
      
      case UButtonVariant.text:
        return baseStyle.copyWith(
          color: Colors.transparent,
        );
      
      case UButtonVariant.ghost:
        return baseStyle.copyWith(
          color: _getGhostColor(color, isDisabled, isInteractive),
        );
    }
  }

  Color _getFilledColor(Color color, bool isDisabled, bool isInteractive) {
    if (isDisabled) {
      return color.withOpacity(0.4);
    }
    if (_isPressed) {
      return color.withOpacity(0.8);
    }
    if (_isHovering) {
      return color.withOpacity(0.9);
    }
    return color;
  }

  Color _getOutlineColor(Color color, bool isDisabled) {
    if (isDisabled) {
      return color.withOpacity(0.4);
    }
    return color;
  }

  Color _getGhostColor(Color color, bool isDisabled, bool isInteractive) {
    if (isDisabled) {
      return Colors.transparent;
    }
    if (_isPressed) {
      return color.withOpacity(0.15);
    }
    if (_isHovering) {
      return color.withOpacity(0.08);
    }
    return Colors.transparent;
  }

  TextStyle _getTextStyle(UThemeData theme, Color color, bool isDisabled) {
    final textColor = _getTextColor(color, isDisabled);
    final fontSize = _getFontSize(theme);

    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: textColor,
    );
  }

  Color _getTextColor(Color color, bool isDisabled) {
    switch (widget.variant) {
      case UButtonVariant.filled:
        return isDisabled ? Colors.white.withOpacity(0.6) : Colors.white;
      case UButtonVariant.outlined:
      case UButtonVariant.text:
      case UButtonVariant.ghost:
        return isDisabled ? color.withOpacity(0.4) : color;
    }
  }

  EdgeInsets _getPadding(UThemeData theme) {
    switch (widget.size) {
      case UButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: theme.spacingMedium,
          vertical: theme.spacingTiny,
        );
      case UButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: theme.spacingLarge,
          vertical: theme.spacingSmall,
        );
      case UButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: theme.spacingXLarge,
          vertical: theme.spacingMedium,
        );
    }
  }

  double _getFontSize(UThemeData theme) {
    switch (widget.size) {
      case UButtonSize.small:
        return 14;
      case UButtonSize.medium:
        return 16;
      case UButtonSize.large:
        return 18;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case UButtonSize.small:
        return 16;
      case UButtonSize.medium:
        return 18;
      case UButtonSize.large:
        return 20;
    }
  }
}
