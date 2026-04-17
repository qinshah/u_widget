import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';

class UContainer extends StatelessWidget {
  const UContainer({
    super.key,
    this.child = const SizedBox.shrink(),
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? radius;

  EdgeInsetsGeometry getPadding(UThemeData theme) {
    return padding ?? theme.paddingMedium;
  }

  Color getBackgroundColor(UThemeData theme) {
    return backgroundColor ?? theme.background;
  }

  Color getBorderColor(UThemeData theme) {
    return borderColor ?? theme.border;
  }

  double getRadius(UThemeData theme) => radius ?? theme.borderRadiusMedium;

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return raw(
      backgroundColor: getBackgroundColor(theme),
      borderColor: getBorderColor(theme),
      padding: getPadding(theme),
      radius: getRadius(theme),
      child: child,
    );
  }

  static Widget raw({
    required Color backgroundColor,
    required Color borderColor,
    required EdgeInsetsGeometry padding,
    required double radius,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

mixin USpacingMixin {
  EdgeInsetsGeometry getDefaultPadding(UThemeData theme) {
    return EdgeInsets.symmetric(
      horizontal: theme.spacingLarge,
      vertical: theme.spacingSmall,
    );
  }

  EdgeInsetsGeometry resolvePadding(
    UThemeData theme,
    EdgeInsetsGeometry? custom,
  ) {
    return custom ?? getDefaultPadding(theme);
  }
}
