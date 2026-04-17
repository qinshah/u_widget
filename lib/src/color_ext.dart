import 'package:flutter/material.dart';

extension ColorExt on Color {
  bool get isBright {
    if (a == 0) return true;
    return computeLuminance() > 0.5;
  }

  Color setAlpha(int alpha) {
    if (a == 0) return this;
    return withAlpha(alpha);
  }
}
