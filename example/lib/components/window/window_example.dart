import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

class WindowExamplePage extends StatefulWidget {
  const WindowExamplePage({super.key});

  @override
  State<WindowExamplePage> createState() => _WindowExamplePageState();
}

class _WindowExamplePageState extends State<WindowExamplePage> {
  List<WindowState> _windows = [];
  bool _showInputDialog = false;
  String _windowTitle = '';
  int _windowCount = 0;

  void _createWindow() {
    if (_windowTitle.isEmpty) return;
    final windowId = 'window_${++_windowCount}';
    setState(() {
      final newWindow = WindowState(
        id: windowId,
        title: _windowTitle,
        x: 50 + (_windows.length % 3) * 100,
        y: 50 + (_windows.length % 3) * 80,
        width: 500,
        height: 350,
        child: CounterWidget(key: ValueKey('counter_$windowId')),
      );
      _windows.add(newWindow);
      _windowTitle = '';
      _showInputDialog = false;
    });
  }

  void _bringToFront(String id) {
    setState(() {
      final index = _windows.indexWhere((w) => w.id == id);
      if (index >= 0 && index != _windows.length - 1) {
        final window = _windows.removeAt(index);
        _windows.add(window);
      }
    });
  }

  void _closeWindow(String id) {
    setState(() {
      _windows.removeWhere((w) => w.id == id);
    });
  }

  void _moveWindow(String id, double x, double y) {
    setState(() {
      final index = _windows.indexWhere((w) => w.id == id);
      if (index >= 0) {
        _windows[index] = _windows[index].copyWith(x: x, y: y);
      }
    });
  }

  void _resizeWindow(String id, double width, double height) {
    setState(() {
      final index = _windows.indexWhere((w) => w.id == id);
      if (index >= 0) {
        _windows[index] = _windows[index].copyWith(width: width, height: height);
      }
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
                      onPressed: () => setState(() => _windows.clear()),
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
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '窗口数量: ${_windows.length}',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                const SizedBox(height: 4),
                Text(
                  '提示: 点击窗口标题栏可切换焦点',
                  style: TextStyle(color: Colors.white.withOpacity(0.4)),
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
            UWindows(
              desktop: _buildDesktop(),
              windows: _windows.map((w) => UWindowData(
                id: w.id,
                title: w.title,
                x: w.x,
                y: w.y,
                width: w.width,
                height: w.height,
                child: w.child,
                onClose: () => _closeWindow(w.id),
                onMove: (x, y) => _moveWindow(w.id, x, y),
                onResize: (width, height) => _resizeWindow(w.id, width, height),
                onFocus: () => _bringToFront(w.id),
              )).toList(),
            ),
            if (_showInputDialog) _buildInputDialog(),
          ],
        ),
      ),
    );
  }
}

class WindowState {
  final String id;
  final String title;
  final double x;
  final double y;
  final double width;
  final double height;
  final Widget child;

  WindowState({
    required this.id,
    required this.title,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.child,
  });

  WindowState copyWith({
    String? id,
    String? title,
    double? x,
    double? y,
    double? width,
    double? height,
    Widget? child,
  }) {
    return WindowState(
      id: id ?? this.id,
      title: title ?? this.title,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      child: child ?? this.child,
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
              '移动窗口、调整大小或切换焦点，\n这个计数器值应该保持不变',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
