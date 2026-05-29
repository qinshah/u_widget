import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

class WindowExamplePage extends StatefulWidget {
  const WindowExamplePage({super.key});

  @override
  State<WindowExamplePage> createState() => _WindowExamplePageState();
}

class _WindowExamplePageState extends State<WindowExamplePage> {
  late final UWindowsManager _manager = UWindowsManager();
  bool _showInputDialog = false;
  String _windowTitle = '';
  int _windowCount = 0;

  void _createWindow() {
    if (_windowTitle.isEmpty) return;
    final windowId = 'window_${++_windowCount}';
    _manager.addWindow(UWindowInfo(
      id: windowId,
      title: _windowTitle,
      x: 50 + (_manager.windows.length % 3) * 100,
      y: 50 + (_manager.windows.length % 3) * 80,
      width: 500,
      height: 350,
      child: CounterWidget(key: ValueKey('counter_$windowId')),
    ));
    setState(() {
      _windowTitle = '';
      _showInputDialog = false;
    });
  }

  Widget _buildDesktop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '桌面',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    UButton(
                      onPressed: () => setState(() => _showInputDialog = true),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 8),
                          Text('新建窗口'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    UButton(
                      backgroundColor: Colors.grey[700],
                      onPressed: () => _manager.clear(),
                      child: const Row(
                        children: [
                          Icon(Icons.delete, size: 18),
                          SizedBox(width: 8),
                          Text('关闭所有'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputDialog() {
    final theme = UTheme.of(context);
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(theme.spacingLarge),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(theme.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 12,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '新建窗口',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '请输入窗口名称',
                  hintStyle: TextStyle(color: theme.secondary),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.secondary),
                    borderRadius: BorderRadius.circular(theme.borderRadiusMedium),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.secondary),
                    borderRadius: BorderRadius.circular(theme.borderRadiusMedium),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.primary),
                    borderRadius: BorderRadius.circular(theme.borderRadiusMedium),
                  ),
                ),
                onChanged: (value) => setState(() => _windowTitle = value),
                onSubmitted: (_) => _createWindow(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  UButton(
                    backgroundColor: theme.secondary.withAlpha(50),
                    contentColor: theme.onSurface,
                    onPressed: () => setState(() => _showInputDialog = false),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  UButton(
                    onPressed: _createWindow,
                    child: const Text('确认'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('窗口组件示例'),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
        elevation: theme.elevationSmall,
      ),
      body: UTheme(
        data: UThemeData.defaultTheme(),
        child: Stack(
          children: [
            // 桌面 + 窗口层 + 任务栏
            Column(
              children: [
                Expanded(
                  child: UWindows(
                    desktop: _buildDesktop(),
                    manager: _manager,
                  ),
                ),
                // 任务栏
                UTaskbar(manager: _manager),
              ],
            ),
            if (_showInputDialog) _buildInputDialog(),
          ],
        ),
      ),
    );
  }
}

class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '计数器状态保持测试',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              '$_counter',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 32),
                  onPressed: () => setState(() => _counter--),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.add, size: 32),
                  onPressed: () => setState(() => _counter++),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '移动窗口、调整大小、最大化/最小化，\n这个计数器值应该保持不变',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
