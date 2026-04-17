import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/src/color_ext.dart';

class UButton extends StatelessWidget {
  const UButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPressed,
    this.enabled = true,
    this.primaryColor,
    this.contentColor,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final bool enabled;
  final Color? primaryColor;
  final Color? contentColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    Color curPrimaryColor = primaryColor ?? theme.primary;
    Color curBorderColor = borderColor ?? theme.border;
    Color curContentColor =
        contentColor ??
        (curPrimaryColor.isBright ? Colors.black : Colors.white);
    MouseCursor cursor = SystemMouseCursors.click;
    VoidCallback? curOnTap = onPressed;
    VoidCallback? curOnLongPressed = onLongPressed;
    if (!enabled) {
      curPrimaryColor = curPrimaryColor.setAlpha(102);
      curContentColor = curContentColor.setAlpha(102);
      curBorderColor = curBorderColor.setAlpha(102);
      cursor = SystemMouseCursors.forbidden;
      curOnTap = null;
      curOnLongPressed = null;
    }
    final curChild = Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacingLarge,
        vertical: theme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: curPrimaryColor,
        border: Border.all(color: curBorderColor, width: 1),
        borderRadius: BorderRadius.circular(theme.borderRadiusMedium),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: curContentColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        child: child,
      ),
    );
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onTap: curOnTap,
        onLongPress: curOnLongPressed,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: theme.animationDuration,
          child: curChild,
        ),
      ),
    );
  }
}
