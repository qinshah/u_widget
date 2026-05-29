import 'package:flutter/material.dart';
import 'u_window.dart';
import 'u_windows_manager.dart';

class UWindows extends StatelessWidget {
  const UWindows({
    super.key,
    required this.desktop,
    required this.manager,
  });

  final Widget desktop;
  final UWindowsManager manager;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final windows = manager.windows;
        return Stack(
          fit: StackFit.expand,
          children: [
            desktop,
            ...windows.asMap().entries.map((entry) {
              final index = entry.key;
              final window = entry.value;
              // 最小化窗口返回0尺寸盒子
              if (window.state == UWindowState.minimized) {
                return const SizedBox.shrink();
              }
              return UWindow(
                key: ValueKey(window.id),
                title: window.title,
                width: window.width,
                height: window.height,
                x: window.x,
                y: window.y,
                isFocused: index == windows.length - 1,
                isMaximized: window.state == UWindowState.maximized,
                onClose: () => manager.closeWindow(window.id),
                onMove: (x, y) => manager.moveWindow(window.id, x, y),
                onResize: (width, height) => manager.resizeWindow(window.id, width, height),
                onFocus: () => manager.bringToFront(window.id),
                onToggleMaximize: () => manager.toggleMaximize(window.id),
                onMinimize: () => manager.minimizeWindow(window.id),
                child: window.child,
              );
            }),
          ],
        );
      },
    );
  }
}
