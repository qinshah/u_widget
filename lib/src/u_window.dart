import 'package:flutter/gestures.dart';
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
    this.onClose,
    this.onMove,
    this.onResize,
    this.onFocus,
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
  final VoidCallback? onClose;
  final void Function(double x, double y)? onMove;
  final void Function(double width, double height)? onResize;
  final VoidCallback? onFocus;
  final bool isFocused;

  @override
  State<UWindow> createState() => _UWindowState();
}

class _UWindowState extends State<UWindow> {
  late double _x;
  late double _y;
  late double _width;
  late double _height;
  bool _isMaximized = false;
  bool _isDragging = false;
  bool _isResizing = false;
  Offset _dragStart = Offset.zero;
  Offset _resizeStart = Offset.zero;
  double _resizeStartWidth = 0;
  double _resizeStartHeight = 0;
  double _resizeStartX = 0;
  double _resizeStartY = 0;
  String _resizeDirection = '';
  String _hoverDirection = '';
  final double _resizeHandleSize = 10.0;

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

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    if (_isMaximized) {
      return Positioned.fill(
        child: MouseRegion(
          cursor: _isDragging
              ? SystemMouseCursors.grabbing
              : _isResizing
                  ? _getResizeCursor()
                  : SystemMouseCursors.basic,
          child: Container(
            decoration: BoxDecoration(
              color: theme.surface,
              border: Border.all(
                color: widget.isFocused ? theme.primary : theme.secondary.withAlpha(100),
                width: widget.isFocused ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                _buildTitleBar(theme),
                Expanded(child: widget.child),
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
          MouseRegion(
            onHover: _handleHover,
            onExit: (_) => setState(() => _hoverDirection = ''),
            cursor: _getCurrentCursor(),
            child: GestureDetector(
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isFocused ? theme.primary : theme.secondary.withAlpha(100),
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
                    _buildTitleBar(theme),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ),
          ),
          _buildResizeHandle(top: 0, left: 0, direction: 'topleft'),
          _buildResizeHandle(top: 0, right: 0, direction: 'topright'),
          _buildResizeHandle(bottom: 0, left: 0, direction: 'bottomleft'),
          _buildResizeHandle(bottom: 0, right: 0, direction: 'bottomright'),
          _buildResizeHandle(top: 0, left: _resizeHandleSize, right: _resizeHandleSize, direction: 'top'),
          _buildResizeHandle(bottom: 0, left: _resizeHandleSize, right: _resizeHandleSize, direction: 'bottom'),
          _buildResizeHandle(left: 0, top: _resizeHandleSize, bottom: _resizeHandleSize, direction: 'left'),
          _buildResizeHandle(right: 0, top: _resizeHandleSize, bottom: _resizeHandleSize, direction: 'right'),
        ],
      ),
    );
  }

  Widget _buildResizeHandle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required String direction,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: MouseRegion(
        cursor: _getCursorForDirection(direction),
        onHover: (_) => setState(() => _hoverDirection = direction),
        onExit: (_) => setState(() => _hoverDirection = ''),
        child: GestureDetector(
          onPanStart: (details) => _startResize(direction, details),
          onPanUpdate: _updateResize,
          onPanEnd: _endResize,
          child: Container(
            width: top != null && bottom == null
                ? null
                : bottom != null && top == null
                    ? null
                    : _resizeHandleSize * 2,
            height: left != null && right == null
                ? null
                : right != null && left == null
                    ? null
                    : _resizeHandleSize * 2,
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(UThemeData theme) {
    return GestureDetector(
      onPanStart: (details) {
        if (_isResizing) return;
        _isDragging = true;
        _dragStart = details.localPosition;
        widget.onFocus?.call();
      },
      onPanUpdate: (details) {
        if (!_isDragging || _isMaximized) return;
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
            _buildTitleButton(Icons.minimize, () => _toggleMaximize()),
            _buildTitleButton(Icons.maximize, () => _toggleMaximize()),
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

  void _toggleMaximize() {
    setState(() {
      _isMaximized = !_isMaximized;
    });
  }

  void _handleHover(PointerHoverEvent event) {
    if (_isResizing || _isDragging) return;
    final localPosition = event.localPosition;
    setState(() {
      _hoverDirection = _getDirectionForPosition(localPosition);
    });
  }

  String _getDirectionForPosition(Offset position) {
    final onTop = position.dy < _resizeHandleSize;
    final onBottom = position.dy > _height - _resizeHandleSize;
    final onLeft = position.dx < _resizeHandleSize;
    final onRight = position.dx > _width - _resizeHandleSize;

    if (onTop && onLeft) return 'topleft';
    if (onTop && onRight) return 'topright';
    if (onBottom && onLeft) return 'bottomleft';
    if (onBottom && onRight) return 'bottomright';
    if (onTop) return 'top';
    if (onBottom) return 'bottom';
    if (onLeft) return 'left';
    if (onRight) return 'right';
    return '';
  }

  MouseCursor _getCurrentCursor() {
    if (_isDragging) return SystemMouseCursors.grabbing;
    if (_isResizing) return _getCursorForDirection(_resizeDirection);
    if (_hoverDirection.isNotEmpty) return _getCursorForDirection(_hoverDirection);
    return SystemMouseCursors.basic;
  }

  MouseCursor _getCursorForDirection(String direction) {
    if (direction.contains('top') && direction.contains('left')) {
      return SystemMouseCursors.resizeUpLeft;
    }
    if (direction.contains('bottom') && direction.contains('right')) {
      return SystemMouseCursors.resizeUpLeft; // 与左上角相同
    }
    if (direction.contains('bottom') && direction.contains('left')) {
      return SystemMouseCursors.resizeDownLeft;
    }
    if (direction.contains('top') && direction.contains('right')) {
      return SystemMouseCursors.resizeDownLeft; // 与左下角相同
    }
    if (direction.contains('left') || direction.contains('right')) {
      return SystemMouseCursors.resizeLeftRight;
    }
    if (direction.contains('top') || direction.contains('bottom')) {
      return SystemMouseCursors.resizeUpDown;
    }
    return SystemMouseCursors.basic;
  }

  MouseCursor _getResizeCursor() {
    return _getCursorForDirection(_resizeDirection);
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isResizing) return;
    final localPosition = details.localPosition;
    final direction = _getDirectionForPosition(localPosition);
    
    if (direction.isNotEmpty) {
      _startResize(direction, details);
    }
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

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isResizing) {
      _updateResize(details);
    } else if (_isDragging) {
      if (_isMaximized) return;
      setState(() {
        _x += details.delta.dx;
        _y += details.delta.dy;
      });
      widget.onMove?.call(_x, _y);
    }
  }

  void _updateResize(DragUpdateDetails details) {
    if (!_isResizing || _isMaximized) return;
    
    final dx = details.globalPosition.dx - _resizeStart.dx;
    final dy = details.globalPosition.dy - _resizeStart.dy;
    
    setState(() {
      if (_resizeDirection.contains('right')) {
        _width = (_resizeStartWidth + dx).clamp(widget.minWidth, double.infinity);
      }
      if (_resizeDirection.contains('left')) {
        final newWidth = (_resizeStartWidth - dx).clamp(widget.minWidth, double.infinity);
        if (newWidth != _width) {
          _x = _resizeStartX + (_resizeStartWidth - newWidth);
          _width = newWidth;
        }
      }
      if (_resizeDirection.contains('bottom')) {
        _height = (_resizeStartHeight + dy).clamp(widget.minHeight, double.infinity);
      }
      if (_resizeDirection.contains('top')) {
        final newHeight = (_resizeStartHeight - dy).clamp(widget.minHeight, double.infinity);
        if (newHeight != _height) {
          _y = _resizeStartY + (_resizeStartHeight - newHeight);
          _height = newHeight;
        }
      }
    });
    
    widget.onResize?.call(_width, _height);
    widget.onMove?.call(_x, _y);
  }

  void _handlePanEnd(DragEndDetails details) {
    _isResizing = false;
    _isDragging = false;
  }

  void _endResize(DragEndDetails details) {
    setState(() {
      _isResizing = false;
    });
  }
}