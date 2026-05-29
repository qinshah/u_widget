import 'package:flutter/material.dart';
import 'u_window.dart';

class UWindows extends StatelessWidget {
  const UWindows({
    super.key,
    required this.desktop,
    this.windows = const [],
  });

  final Widget desktop;
  final List<UWindowData> windows;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        desktop,
        ...windows.map((window) {
          final index = windows.indexOf(window);
          if (!window.isVisible) return const SizedBox.shrink();
          return UWindow(
            key: ValueKey(window.id),
            title: window.title,
            width: window.width,
            height: window.height,
            x: window.x,
            y: window.y,
            isFocused: index == windows.length - 1,
            onClose: window.onClose,
            onMove: window.onMove,
            onResize: window.onResize,
            onFocus: window.onFocus,
            child: window.child,
          );
        }),
      ],
    );
  }
}

class UWindowData {
  final String id;
  final String title;
  final Widget child;
  final double x;
  final double y;
  final double width;
  final double height;
  final bool isMaximized;
  final bool isVisible;
  final VoidCallback? onClose;
  final void Function(double x, double y)? onMove;
  final void Function(double width, double height)? onResize;
  final VoidCallback? onFocus;

  UWindowData({
    required this.id,
    required this.title,
    required this.child,
    this.x = 100,
    this.y = 100,
    this.width = 600,
    this.height = 400,
    this.isMaximized = false,
    this.isVisible = true,
    this.onClose,
    this.onMove,
    this.onResize,
    this.onFocus,
  });
}
