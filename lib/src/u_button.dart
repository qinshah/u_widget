import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/src/color_ext.dart';
import 'package:u_widget/src/u_container.dart';

class UButton extends UContainer {
  const UButton({
    super.key,
    this.onPressed,
    this.onLongPressed,
    this.onSecondaryTap,
    this.onTertiaryTapUp,
    this.disable = false,
    this.contentColor,
    super.backgroundColor,
    super.borderColor,
    super.padding,
    super.radius,
    required super.child,
  });

  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;

  /// 鼠标右键点击事件回调
  final VoidCallback? onSecondaryTap;

  /// 鼠标中键点击事件回调
  final void Function(TapUpDetails)? onTertiaryTapUp;

  /// 是否启用
  final bool disable;
  final Color? contentColor;

  @override
  Color getBackgroundColor(UThemeData theme) {
    return backgroundColor ?? theme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    Color curBackgroundColor = getBackgroundColor(theme);
    Color curBorderColor = getBorderColor(theme);
    Color curContentColor =
        contentColor ??
        (curBackgroundColor.isBright ? Colors.black : Colors.white);
    MouseCursor cursor = SystemMouseCursors.click;
    VoidCallback? curOnTap = onPressed;
    VoidCallback? curOnLongPressed = onLongPressed;
    if (disable) {
      curBackgroundColor = curBackgroundColor.setAlpha(102);
      curContentColor = curContentColor.setAlpha(102);
      curBorderColor = curBorderColor.setAlpha(102);
      cursor = SystemMouseCursors.forbidden;
      curOnTap = null;
      curOnLongPressed = null;
    }
    final uContainer = UContainer.raw(
      backgroundColor: curBackgroundColor,
      borderColor: curBorderColor,
      padding: getPadding(theme),
      radius: getRadius(theme),
      child: IconTheme(
        data: IconThemeData(color: curContentColor),
        child: DefaultTextStyle(
          style: TextStyle(color: curContentColor),
          child: child,
        ),
      ),
    );
    return raw(
      cursor: cursor,
      child: uContainer,
      onTap: curOnTap,
      onLongPress: curOnLongPressed,
      onSecondaryTap: onSecondaryTap,
      onTertiaryTapUp: onTertiaryTapUp,
    );
  }

  static Widget raw({
    required MouseCursor cursor,
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onSecondaryTap,
    void Function(TapUpDetails)? onTertiaryTapUp,
  }) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        onTertiaryTapUp: onTertiaryTapUp,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}
