import 'package:flutter/material.dart';

/// 窗口状态枚举
enum UWindowState {
  /// 正常状态
  normal,
  /// 最大化
  maximized,
  /// 最小化（隐藏到任务栏）
  minimized,
}

/// 窗口数据模型
class UWindowInfo {
  final String id;
  final String title;
  final Widget child;
  double x;
  double y;
  double width;
  double height;
  UWindowState state;

  UWindowInfo({
    required this.id,
    required this.title,
    required this.child,
    this.x = 100,
    this.y = 100,
    this.width = 600,
    this.height = 400,
    this.state = UWindowState.normal,
  });

  UWindowInfo copyWith({
    String? id,
    String? title,
    Widget? child,
    double? x,
    double? y,
    double? width,
    double? height,
    UWindowState? state,
  }) {
    return UWindowInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      child: child ?? this.child,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      state: state ?? this.state,
    );
  }
}

/// 窗口管理器 - 使用 ChangeNotifier 实现状态管理
class UWindowsManager extends ChangeNotifier {
  final List<UWindowInfo> _windows = [];

  /// 获取所有窗口（按Z轴顺序，最后一个是最顶层）
  List<UWindowInfo> get windows => List.unmodifiable(_windows);

  /// 获取可见窗口（非最小化）
  List<UWindowInfo> get visibleWindows =>
      _windows.where((w) => w.state != UWindowState.minimized).toList();

  /// 获取当前焦点窗口ID（最后一个可见窗口）
  String? get focusedWindowId {
    for (int i = _windows.length - 1; i >= 0; i--) {
      if (_windows[i].state != UWindowState.minimized) {
        return _windows[i].id;
      }
    }
    return null;
  }

  /// 添加窗口
  void addWindow(UWindowInfo window) {
    _windows.add(window);
    notifyListeners();
  }

  /// 关闭窗口
  void closeWindow(String id) {
    _windows.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  /// 将窗口移到最前面（Z轴置顶）
  void bringToFront(String id) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index >= 0 && index != _windows.length - 1) {
      final window = _windows.removeAt(index);
      _windows.add(window);
      notifyListeners();
    }
  }

  /// 移动窗口位置
  void moveWindow(String id, double x, double y) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index >= 0) {
      _windows[index].x = x;
      _windows[index].y = y;
      notifyListeners();
    }
  }

  /// 调整窗口大小
  void resizeWindow(String id, double width, double height) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index >= 0) {
      _windows[index].width = width;
      _windows[index].height = height;
      notifyListeners();
    }
  }

  /// 切换最大化/正常状态
  void toggleMaximize(String id) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index >= 0) {
      final window = _windows[index];
      window.state = window.state == UWindowState.maximized
          ? UWindowState.normal
          : UWindowState.maximized;
      notifyListeners();
    }
  }

  /// 最小化窗口
  void minimizeWindow(String id) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index >= 0) {
      _windows[index].state = UWindowState.minimized;
      notifyListeners();
    }
  }

  /// 恢复窗口（从最小化状态恢复）
  void restoreWindow(String id) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index >= 0) {
      _windows[index].state = UWindowState.normal;
      // 恢复时同时前置
      if (index != _windows.length - 1) {
        final window = _windows.removeAt(index);
        _windows.add(window);
      }
      notifyListeners();
    }
  }

  /// 点击任务栏项：如果已最小化则恢复，否则前置
  void onTaskbarItemTap(String id) {
    final index = _windows.indexWhere((w) => w.id == id);
    if (index < 0) return;

    final window = _windows[index];
    if (window.state == UWindowState.minimized) {
      window.state = UWindowState.normal;
      if (index != _windows.length - 1) {
        final w = _windows.removeAt(index);
        _windows.add(w);
      }
    } else {
      if (index != _windows.length - 1) {
        final w = _windows.removeAt(index);
        _windows.add(w);
      }
    }
    notifyListeners();
  }

  /// 清空所有窗口
  void clear() {
    _windows.clear();
    notifyListeners();
  }
}
