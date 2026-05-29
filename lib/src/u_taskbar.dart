import 'package:flutter/material.dart';
import 'u_windows_manager.dart';

/// 任务栏组件 - 显示所有窗口并提供切换功能
class UTaskbar extends StatelessWidget {
  const UTaskbar({
    super.key,
    required this.manager,
    this.height = 48,
    this.backgroundColor,
    this.startButton,
  });

  final UWindowsManager manager;
  final double height;
  final Color? backgroundColor;
  final Widget? startButton;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final windows = manager.windows;
        final focusedId = manager.focusedWindowId;

        return Container(
          height: height,
          color: backgroundColor ?? Colors.black.withOpacity(0.8),
          child: Row(
            children: [
              const SizedBox(width: 8),
              // 开始按钮
              startButton ?? _defaultStartButton(),
              const SizedBox(width: 8),
              const VerticalDivider(color: Colors.white24, width: 1),
              const SizedBox(width: 8),
              // 窗口列表
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: windows.length,
                  itemBuilder: (context, index) {
                    final window = windows[index];
                    final isMinimized = window.state == UWindowState.minimized;
                    final isFocused = window.id == focusedId;

                    return GestureDetector(
                      onTap: () => manager.onTaskbarItemTap(window.id),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isFocused
                              ? Colors.white.withOpacity(0.2)
                              : isMinimized
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: isFocused
                              ? Border.all(color: Colors.white.withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isMinimized ? Icons.indeterminate_check_box : Icons.web_asset,
                              color: isFocused ? Colors.white : Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              window.title,
                              style: TextStyle(
                                color: isFocused ? Colors.white : Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // 时间
              _buildClock(),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _defaultStartButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.window, color: Colors.white, size: 20),
    );
  }

  Widget _buildClock() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final now = DateTime.now();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
