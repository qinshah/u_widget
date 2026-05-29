import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';

class UWindow extends StatefulWidget {
  const UWindow({
    super.key,
    required this.title,
    required this.child,
    this.width = 600,
    this.height = 400,
    this.minWidth = 200,
    this.minHeight = 200,
    this.x = 100,
    this.y = 100,
    this.isMaximized = false,
    this.onClose,
    this.onMove,
    this.onResize,
    this.onFocus,
    this.onToggleMaximize,
    this.onMinimize,
    this.isFocused = false,
  });

  final String title;
  final Widget child;
  final double width;
  final double height;
  final double minWidth;
  final double minHeight;
  final double x;
  final double y;
  final bool isMaximized;
  final VoidCallback? onClose;
  final void Function(double x, double y)? onMove;
  final void Function(double width, double height)? onResize;
  final VoidCallback? onFocus;
  final VoidCallback? onToggleMaximize;
  final VoidCallback? onMinimize;
  final bool isFocused;

  @override
  State<UWindow> createState() => _UWindowState();
}

class _UWindowState extends State<UWindow> {
  late double _x;
  late double _y;
  late double _width;
  late double _height;
  bool _isDragging = false;
  bool _isResizing = false;
  Offset _resizeStart = Offset.zero;
  double _resizeStartWidth = 0;
  double _resizeStartHeight = 0;
  double _resizeStartX = 0;
  double _resizeStartY = 0;
  String _resizeDirection = '';

  // GlobalKey 用于保持窗口内容状态，无论外部结构如何变化
  late final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _x = widget.x;
    _y = widget.y;
    _width = widget.width;
    _height = widget.height;
  }

  @override
  void didUpdateWidget(UWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.x != oldWidget.x || widget.y != oldWidget.y) {
      _x = widget.x;
      _y = widget.y;
    }
  }

  late UThemeData _theme = UTheme.of(context);

  @override
  Widget build(BuildContext context) {
    _theme = UTheme.of(context);

    // 使用 GlobalKey 包裹内容，确保最大化/最小化时状态不丢失
    final content = KeyedSubtree(
      key: _contentKey,
      child: widget.child,
    );

    if (widget.isMaximized) {
      return Positioned.fill(
        child: MouseRegion(
          cursor: _isDragging
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.basic,
          child: Container(
            decoration: BoxDecoration(
              color: _theme.surface,
              border: Border.all(
                color: widget.isFocused
                    ? _theme.primary
                    : _theme.secondary.withAlpha(100),
                width: widget.isFocused ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                _buildTitleBar(_theme),
                Expanded(child: content),
              ],
            ),
          ),
        ),
      );
    }
    return Positioned(
      left: _x,
      top: _y,
      width: _width,
      height: _height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 主窗口内容
          Container(
            decoration: BoxDecoration(
              color: _theme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isFocused
                    ? _theme.primary
                    : _theme.secondary.withAlpha(100),
                width: widget.isFocused ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(widget.isFocused ? 80 : 40),
                  blurRadius: widget.isFocused ? 12 : 8,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTitleBar(_theme),
                Expanded(child: content),
              ],
            ),
          ),
          // 四个边的调整手柄
          _buildResizeHandle(
            top: 0,
            left: 0,
            right: 0,
            height: 5,
            direction: 'top',
            cursor: SystemMouseCursors.resizeUpDown,
          ),
          _buildResizeHandle(
            bottom: 0,
            left: 0,
            right: 0,
            height: 5,
            direction: 'bottom',
            cursor: SystemMouseCursors.resizeUpDown,
          ),
          _buildResizeHandle(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            direction: 'left',
            cursor: SystemMouseCursors.resizeLeftRight,
          ),
          _buildResizeHandle(
            right: 0,
            top: 0,
            bottom: 0,
            width: 5,
            direction: 'right',
            cursor: SystemMouseCursors.resizeLeftRight,
          ),
          // 四个角的调整手柄
          _buildResizeHandle(
            top: 0,
            left: 0,
            width: 10,
            height: 10,
            direction: 'topleft',
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
          ),
          _buildResizeHandle(
            top: 0,
            right: 0,
            width: 10,
            height: 10,
            direction: 'topright',
            cursor: SystemMouseCursors.resizeUpRightDownLeft,
          ),
          _buildResizeHandle(
            bottom: 0,
            left: 0,
            width: 10,
            height: 10,
            direction: 'bottomleft',
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
          ),
          _buildResizeHandle(
            bottom: 0,
            right: 0,
            width: 10,
            height: 10,
            direction: 'bottomright',
            cursor: SystemMouseCursors.resizeUpRightDownLeft,
          ),
        ],
      ),
    );
  }

  Widget _buildResizeHandle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    double? width,
    double? height,
    required String direction,
    required MouseCursor cursor,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onPanStart: (details) => _startResize(direction, details),
          onPanUpdate: _updateResize,
          onPanEnd: _endResize,
          child: Container(color: Colors.transparent, width: width, height: height),
        ),
      ),
    );
  }

  Widget _buildTitleBar(UThemeData theme) {
    return GestureDetector(
      onPanStart: (details) {
        if (_isResizing) return;
        _isDragging = true;
        widget.onFocus?.call();
      },
      onPanUpdate: (details) {
        if (!_isDragging || widget.isMaximized) return;
        setState(() {
          _x += details.delta.dx;
          _y += details.delta.dy;
        });
        widget.onMove?.call(_x, _y);
      },
      onPanEnd: (_) => _isDragging = false,
      child: Container(
        height: 36,
        color: widget.isFocused ? theme.primary : theme.surface,
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  color: widget.isFocused ? Colors.white : theme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildTitleButton(Icons.minimize, widget.onMinimize),
            _buildTitleButton(
              widget.isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
              widget.onToggleMaximize,
            ),
            _buildTitleButton(Icons.close, widget.onClose),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleButton(IconData icon, VoidCallback? onPressed) {
    final theme = UTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 36,
          child: Icon(
            icon,
            size: 16,
            color: widget.isFocused ? Colors.white : theme.onSurface,
          ),
        ),
      ),
    );
  }

  void _startResize(String direction, DragStartDetails details) {
    setState(() {
      _isResizing = true;
      _resizeDirection = direction;
      _resizeStart = details.globalPosition;
      _resizeStartWidth = _width;
      _resizeStartHeight = _height;
      _resizeStartX = _x;
      _resizeStartY = _y;
    });
    widget.onFocus?.call();
  }

  void _updateResize(DragUpdateDetails details) {
    if (!_isResizing || widget.isMaximized) return;

    final dx = details.globalPosition.dx - _resizeStart.dx;
    final dy = details.globalPosition.dy - _resizeStart.dy;

    setState(() {
      if (_resizeDirection.contains('right')) {
        _width = (_resizeStartWidth + dx).clamp(
          widget.minWidth,
          double.infinity,
        );
      }
      if (_resizeDirection.contains('left')) {
        final newWidth = (_resizeStartWidth - dx).clamp(
          widget.minWidth,
          double.infinity,
        );
        if (newWidth != _width) {
          _x = _resizeStartX + (_resizeStartWidth - newWidth);
          _width = newWidth;
        }
      }
      if (_resizeDirection.contains('bottom')) {
        _height = (_resizeStartHeight + dy).clamp(
          widget.minHeight,
          double.infinity,
        );
      }
      if (_resizeDirection.contains('top')) {
        final newHeight = (_resizeStartHeight - dy).clamp(
          widget.minHeight,
          double.infinity,
        );
        if (newHeight != _height) {
          _y = _resizeStartY + (_resizeStartHeight - newHeight);
          _height = newHeight;
        }
      }
    });

    widget.onResize?.call(_width, _height);
    widget.onMove?.call(_x, _y);
  }

  void _endResize(DragEndDetails details) {
    setState(() {
      _isResizing = false;
    });
  }
}
