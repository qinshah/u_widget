import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:u_design/u_design.dart';

class UTextEditor extends StatefulWidget {
  const UTextEditor({
    super.key,
    this.cntlr,
    this.focusNode,
    this.initialText = '',
    this.showLineNumbers = true,
    this.showStatusBar = true,
    this.lineNumberWidth = 48.0,
    this.fontSize = 14.0,
    this.lineHeight = 1.5,
    this.padding,
    this.onChanged,
  });

  final TextEditingController? cntlr;
  final FocusNode? focusNode;
  final String initialText;
  final bool showLineNumbers;
  final bool showStatusBar;
  final double lineNumberWidth;
  final double fontSize;
  final double lineHeight;
  final EdgeInsets? padding;
  final ValueChanged<String>? onChanged;

  @override
  State<UTextEditor> createState() => _UTextEditorState();
}

class _UTextEditorState extends State<UTextEditor>
    with WidgetsBindingObserver
    implements TextInputClient {
  late final TextEditingController _cntlr;
  late final FocusNode _focusNode;
  final ScrollController _scrollController = ScrollController();

  TextInputConnection? _textInputConnection;
  Timer? _cursorTimer;
  bool _cursorVisibilityNotifier = true;
  bool _hasFocus = false;

  double _viewportHeight = 0;
  double _viewportWidth = 0;
  double _lineHeightPx = 0;

  late TextStyle _textStyle;
  late ui.TextStyle _uiTextStyle;
  late TextStyle _lineNumberStyle;
  Color _textColor = Colors.black;
  Color _lineNumberColor = Colors.grey;
  Color _lineNumberCurrentColor = Colors.blue;

  final Map<int, TextPainter> _linePainterCache = {};
  String _lastTextForCache = '';

  EdgeInsets get _padding =>
      widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  double get _textWidth {
    double w = _viewportWidth - _padding.horizontal;
    if (widget.showLineNumbers) w -= widget.lineNumberWidth;
    return math.max(w, 1);
  }

  double get _contentHeight => _totalLines * _lineHeightPx;

  int get _totalLines {
    if (_cntlr.text.isEmpty) return 1;
    return '\n'.allMatches(_cntlr.text).length + 1;
  }

  int get _cursorLine {
    final offset = _cntlr.selection.baseOffset;
    if (offset < 0) return 0;
    final before = _cntlr.text.substring(0, math.min(offset, _cntlr.text.length));
    return '\n'.allMatches(before).length;
  }

  int get _cursorColumn {
    final offset = _cntlr.selection.baseOffset;
    if (offset <= 0) return 0;
    final lastNewline = _cntlr.text.lastIndexOf('\n', offset - 1);
    return offset - (lastNewline + 1);
  }

  bool get _hasInputConnection =>
      _textInputConnection != null && _textInputConnection!.attached;

  TextEditingValue get _value => _cntlr.value;

  @override
  void initState() {
    super.initState();
    _cntlr = widget.cntlr ?? TextEditingController(text: widget.initialText);
    _focusNode = widget.focusNode ?? FocusNode();
    _cntlr.addListener(_didChangeTextEditingValue);
    _focusNode.addListener(_handleFocusChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = UTheme.of(context);
    _textColor = theme.onSurface;
    _lineNumberColor = theme.secondary;
    _lineNumberCurrentColor = theme.primary;
    _lineHeightPx = widget.fontSize * widget.lineHeight;
    _textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      color: _textColor,
    );
    _uiTextStyle = ui.TextStyle(
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      color: _textColor,
    );
    _lineNumberStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      color: _lineNumberColor,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cntlr.removeListener(_didChangeTextEditingValue);
    _focusNode.removeListener(_handleFocusChanged);
    _scrollController.removeListener(_onScroll);
    _closeInputConnectionIfNeeded();
    _stopCursorTimer();
    _scrollController.dispose();
    _clearPainterCache();
    if (widget.cntlr == null) _cntlr.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _clearPainterCache() {
    for (final p in _linePainterCache.values) {
      p.dispose();
    }
    _linePainterCache.clear();
    _lastTextForCache = '';
  }

  void _didChangeTextEditingValue() {
    _updateRemoteEditingValueIfNeeded();
    if (mounted) setState(() {});
    widget.onChanged?.call(_cntlr.text);
  }

  void _handleFocusChanged() {
    _hasFocus = _focusNode.hasFocus;
    _openOrCloseInputConnectionIfNeeded();
    _startOrStopCursorTimerIfNeeded();
  }

  void _openOrCloseInputConnectionIfNeeded() {
    if (_hasFocus && _focusNode.consumeKeyboardToken()) {
      _openInputConnection();
    } else if (!_hasFocus) {
      _closeInputConnectionIfNeeded();
      _cntlr.clearComposing();
    }
  }

  void _openInputConnection() {
    if (_hasInputConnection) {
      _textInputConnection!.updateConfig(
        const TextInputConfiguration(
          inputType: TextInputType.multiline,
          inputAction: TextInputAction.newline,
          enableSuggestions: false,
          autocorrect: false,
        ),
      );
      _textInputConnection!.show();
      return;
    }
    final localValue = _value;
    _textInputConnection = TextInput.attach(
      this,
      const TextInputConfiguration(
        inputType: TextInputType.multiline,
        inputAction: TextInputAction.newline,
        enableSuggestions: false,
        autocorrect: false,
      ),
    );
    _textInputConnection!
      ..setStyle(
        fontFamily: _textStyle.fontFamily,
        fontSize: _textStyle.fontSize,
        fontWeight: _textStyle.fontWeight,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.start,
      )
      ..setEditingState(localValue)
      ..show();
  }

  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
    }
  }

  void _updateRemoteEditingValueIfNeeded() {
    if (!_hasInputConnection) return;
    final localValue = _value;
    _textInputConnection?.setEditingState(localValue);
  }

  void requestKeyboard() {
    if (_hasFocus) {
      _openInputConnection();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _startOrStopCursorTimerIfNeeded() {
    if (!_hasFocus) {
      _stopCursorTimer();
      return;
    }
    _startCursorBlink();
  }

  void _startCursorBlink() {
    _cursorVisibilityNotifier = true;
    _stopCursorTimer();
    _cursorTimer = Timer.periodic(
      const Duration(milliseconds: 530),
      (_) {
        if (!mounted) return;
        setState(() => _cursorVisibilityNotifier = !_cursorVisibilityNotifier);
      },
    );
  }

  void _stopCursorTimer() {
    _cursorTimer?.cancel();
    _cursorTimer = null;
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() {});
  }

  double get _scrollOffset =>
      _scrollController.hasClients ? _scrollController.offset : 0;

  void _ensureCursorVisible() {
    if (!_scrollController.hasClients) return;
    final cursorY = _cursorLine * _lineHeightPx;
    final visibleTop = _scrollOffset;
    final visibleBottom = visibleTop + _viewportHeight;
    if (cursorY < visibleTop) {
      _scrollController.jumpTo(cursorY);
    } else if (cursorY + _lineHeightPx > visibleBottom) {
      _scrollController.jumpTo(
        cursorY + _lineHeightPx - _viewportHeight + _padding.vertical,
      );
    }
  }

  @override
  TextEditingValue? get currentTextEditingValue => _value;

  @override
  void updateEditingValue(TextEditingValue value) {
    final localValue = _value;
    if (value == localValue) return;
    _cntlr.value = value;
    _restartCursorBlink();
    _ensureCursorVisible();
  }

  @override
  void performAction(TextInputAction action) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void connectionClosed() {
    if (_hasInputConnection) {
      _textInputConnection?.connectionClosedReceived();
      _textInputConnection = null;
      _focusNode.unfocus();
    }
  }

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void showToolbar() {}

  @override
  void didChangeInputControl(TextInputControl? old, TextInputControl? now) {
    if (_hasFocus && _hasInputConnection) {
      old?.hide();
      now?.show();
    }
  }

  @override
  void insertContent(KeyboardInsertedContent content) {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void performSelector(String selectorName) {}

  void _restartCursorBlink() {
    if (!_hasFocus) return;
    _cursorVisibilityNotifier = true;
    _startCursorBlink();
  }

  void _onTapDown(TapDownDetails details) {
    requestKeyboard();
    final pos = _offsetToPosition(details.localPosition);
    _setCursor(pos);
  }

  void _onPanStart(DragStartDetails details) {
    final pos = _offsetToPosition(details.localPosition);
    _setCursor(pos);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final pos = _offsetToPosition(details.localPosition);
    _setCursor(pos);
  }

  void _setCursor((int line, int column) pos) {
    int offset = 0;
    final lines = _cntlr.text.split('\n');
    for (int i = 0; i < pos.$1 && i < lines.length; i++) {
      offset += lines[i].length + 1;
    }
    offset += pos.$2;
    offset = offset.clamp(0, _cntlr.text.length);
    _cntlr.selection = TextSelection.collapsed(offset: offset);
  }

  (int line, int column) _offsetToPosition(Offset offset) {
    double dx = offset.dx - _padding.left;
    if (widget.showLineNumbers) dx -= widget.lineNumberWidth;
    double dy = offset.dy - _padding.top + _scrollOffset;

    final lines = _cntlr.text.split('\n');
    int line = (dy / _lineHeightPx).floor().clamp(0, lines.length - 1);

    final painter = _getOrCreateLinePainter(line, lines[line]);
    if (painter == null) return (line, 0);

    final pos = painter.getPositionForOffset(Offset(dx, _lineHeightPx / 2));
    return (line, pos.offset.clamp(0, lines[line].length));
  }

  TextPainter? _getOrCreateLinePainter(int lineIndex, String lineText) {
    if (_lastTextForCache != _cntlr.text) {
      _clearPainterCache();
      _lastTextForCache = _cntlr.text;
    }
    if (_linePainterCache.containsKey(lineIndex)) {
      return _linePainterCache[lineIndex]!;
    }
    final painter = TextPainter(
      text: TextSpan(text: lineText, style: _textStyle),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: _textWidth);
    _linePainterCache[lineIndex] = painter;
    return painter;
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    final logical = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    final oldOffset = _cntlr.selection.baseOffset;
    final text = _cntlr.text;

    if (logical == LogicalKeyboardKey.arrowLeft) {
      if (isCtrl) {
        _moveCursorWordLeft(oldOffset);
      } else {
        _cntlr.selection = TextSelection.collapsed(
          offset: math.max(0, oldOffset - 1),
        );
      }
      _ensureCursorVisible();
      return;
    }
    if (logical == LogicalKeyboardKey.arrowRight) {
      if (isCtrl) {
        _moveCursorWordRight(oldOffset);
      } else {
        _cntlr.selection = TextSelection.collapsed(
          offset: math.min(text.length, oldOffset + 1),
        );
      }
      _ensureCursorVisible();
      return;
    }
    if (logical == LogicalKeyboardKey.arrowUp) {
      final line = _cursorLine;
      if (line > 0) {
        final col = _cursorColumn;
        final prevLineLen = text.split('\n')[line - 1].length;
        int newOffset = oldOffset - col - 1;
        newOffset -= (col > prevLineLen ? col - prevLineLen : 0);
        _cntlr.selection = TextSelection.collapsed(offset: math.max(0, newOffset));
      }
      _ensureCursorVisible();
      return;
    }
    if (logical == LogicalKeyboardKey.arrowDown) {
      final line = _cursorLine;
      final lines = text.split('\n');
      if (line < lines.length - 1) {
        final col = _cursorColumn;
        int newOffset = oldOffset + (lines[line].length - col) + 1;
        newOffset += math.min(col, lines[line + 1].length);
        _cntlr.selection = TextSelection.collapsed(
          offset: math.min(text.length, newOffset),
        );
      }
      _ensureCursorVisible();
      return;
    }
    if (logical == LogicalKeyboardKey.home) {
      _cntlr.selection = TextSelection.collapsed(offset: oldOffset - _cursorColumn);
      return;
    }
    if (logical == LogicalKeyboardKey.end) {
      final lines = text.split('\n');
      _cntlr.selection = TextSelection.collapsed(
        offset: oldOffset - _cursorColumn + lines[_cursorLine].length,
      );
      return;
    }
    if (logical == LogicalKeyboardKey.backspace || logical == LogicalKeyboardKey.delete) {
      _handleDelete(logical == LogicalKeyboardKey.delete);
      return;
    }
    if (logical == LogicalKeyboardKey.enter || logical == LogicalKeyboardKey.numpadEnter) {
      _insertNewline();
      return;
    }
    if (logical == LogicalKeyboardKey.tab) {
      _insertText('  ');
      return;
    }
    if (isCtrl && logical == LogicalKeyboardKey.keyC) {
      _copy();
      return;
    }
    if (isCtrl && logical == LogicalKeyboardKey.keyV) {
      _paste();
      return;
    }
    if (isCtrl && logical == LogicalKeyboardKey.keyX) {
      _copy();
      return;
    }
  }

  void _handleDelete(bool forward) {
    final text = _cntlr.text;
    final offset = _cntlr.selection.baseOffset;
    if (forward) {
      if (offset >= text.length) return;
      _cntlr.value = TextEditingValue(
        text: text.substring(0, offset) + text.substring(offset + 1),
        selection: TextSelection.collapsed(offset: offset),
      );
    } else {
      if (offset <= 0) return;
      _cntlr.value = TextEditingValue(
        text: text.substring(0, offset - 1) + text.substring(offset),
        selection: TextSelection.collapsed(offset: offset - 1),
      );
    }
  }

  void _insertNewline() {
    final text = _cntlr.text;
    final offset = _cntlr.selection.baseOffset;
    _cntlr.value = TextEditingValue(
      text: '${text.substring(0, offset)}\n${text.substring(offset)}',
      selection: TextSelection.collapsed(offset: offset + 1),
    );
    _ensureCursorVisible();
  }

  void _insertText(String insertText) {
    final text = _cntlr.text;
    final offset = _cntlr.selection.baseOffset;
    _cntlr.value = TextEditingValue(
      text: '${text.substring(0, offset)}$insertText${text.substring(offset)}',
      selection: TextSelection.collapsed(offset: offset + insertText.length),
    );
    _ensureCursorVisible();
  }

  void _moveCursorWordLeft(int offset) {
    final text = _cntlr.text;
    int pos = offset;
    while (pos > 0 && text[pos - 1] == ' ') {
      pos--;
    }
    while (pos > 0 && text[pos - 1] != ' ') {
      pos--;
    }
    _cntlr.selection = TextSelection.collapsed(offset: pos);
  }

  void _moveCursorWordRight(int offset) {
    final text = _cntlr.text;
    int pos = offset;
    while (pos < text.length && text[pos] != ' ') {
      pos++;
    }
    while (pos < text.length && text[pos] == ' ') {
      pos++;
    }
    _cntlr.selection = TextSelection.collapsed(offset: pos);
  }

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: _cntlr.text));
  }

  void _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    _insertText(data!.text!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    if (_lastTextForCache != _cntlr.text) {
      _clearPainterCache();
      _lastTextForCache = _cntlr.text;
    }
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (_, event) {
        _onKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: _onTapDown,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _viewportHeight = constraints.maxHeight;
                  _viewportWidth = constraints.maxWidth;
                  return SingleChildScrollView(
                    controller: _scrollController,
                    child: SizedBox(
                      height: math.max(_contentHeight + _padding.vertical, _viewportHeight),
                      width: double.infinity,
                      child: CustomPaint(
                        size: Size(
                          _viewportWidth,
                          math.max(_contentHeight + _padding.vertical, _viewportHeight),
                        ),
                        painter: _EditorPainter(
                          controller: _cntlr,
                          cursorVisible: _cursorVisibilityNotifier && _hasFocus,
                          textStyle: _textStyle,
                          lineHeight: _lineHeightPx,
                          padding: _padding,
                          scrollOffset: _scrollOffset,
                          viewportHeight: _viewportHeight,
                          textColor: _textColor,
                          showLineNumbers: widget.showLineNumbers,
                          lineNumberWidth: widget.lineNumberWidth,
                          lineNumberStyle: _lineNumberStyle,
                          lineNumberCurrentColor: _lineNumberCurrentColor,
                          lineNumberColor: _lineNumberColor,
                          textWidth: _textWidth,
                          getOrCreateLinePainter: _getOrCreateLinePainter,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.showStatusBar) _buildStatusBar(theme),
        ],
      ),
    );
  }

  Widget _buildStatusBar(UThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(color: theme.secondary.withValues(alpha: 0.2)),
        ),
      ),
      child: DefaultTextStyle(
        style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: theme.secondary),
        child: Row(
          children: [
            Text('行 ${_cursorLine + 1}, 列 ${_cursorColumn + 1}'),
            const Spacer(),
            Text('共 $_totalLines 行'),
          ],
        ),
      ),
    );
  }
}

class _EditorPainter extends CustomPainter {
  final TextEditingController controller;
  final bool cursorVisible;
  final TextStyle textStyle;
  final double lineHeight;
  final EdgeInsets padding;
  final double scrollOffset;
  final double viewportHeight;
  final Color textColor;
  final bool showLineNumbers;
  final double lineNumberWidth;
  final TextStyle lineNumberStyle;
  final Color lineNumberCurrentColor;
  final Color lineNumberColor;
  final double textWidth;
  final TextPainter? Function(int lineIndex, String lineText) getOrCreateLinePainter;

  _EditorPainter({
    required this.controller,
    required this.cursorVisible,
    required this.textStyle,
    required this.lineHeight,
    required this.padding,
    required this.scrollOffset,
    required this.viewportHeight,
    required this.textColor,
    required this.showLineNumbers,
    required this.lineNumberWidth,
    required this.lineNumberStyle,
    required this.lineNumberCurrentColor,
    required this.lineNumberColor,
    required this.textWidth,
    required this.getOrCreateLinePainter,
  });

  int get _totalLines {
    if (controller.text.isEmpty) return 1;
    return '\n'.allMatches(controller.text).length + 1;
  }

  int get _cursorLine {
    final offset = controller.selection.baseOffset;
    if (offset < 0) return 0;
    final before = controller.text.substring(0, math.min(offset, controller.text.length));
    return '\n'.allMatches(before).length;
  }

  int get _cursorColumn {
    final offset = controller.selection.baseOffset;
    if (offset <= 0) return 0;
    final lastNewline = controller.text.lastIndexOf('\n', offset - 1);
    return offset - (lastNewline + 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final lines = controller.text.isEmpty ? <String>[''] : controller.text.split('\n');
    final startLine = math.max(0, (scrollOffset / lineHeight).floor() - 2);
    final endLine = math.min(
      lines.length,
      ((scrollOffset + viewportHeight) / lineHeight).ceil() + 2,
    );

    final textStartX = padding.left + (showLineNumbers ? lineNumberWidth : 0);

    if (showLineNumbers) {
      _paintLineNumbers(canvas, size, lines, startLine, endLine);
    }

    for (int i = startLine; i < endLine; i++) {
      final y = padding.top + i * lineHeight;
      if (y + lineHeight < scrollOffset - lineHeight ||
          y > scrollOffset + viewportHeight + lineHeight) {
        continue;
      }
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(textStartX, y, textWidth, lineHeight + 1));
      final painter = getOrCreateLinePainter(i, lines[i]);
      if (painter != null) {
        painter.paint(canvas, Offset(textStartX, y));
      }
      canvas.restore();
    }

    if (cursorVisible) {
      _paintCursor(canvas, lines, textStartX);
    }
  }

  void _paintCursor(Canvas canvas, List<String> lines, double textStartX) {
    final cl = _cursorLine;
    if (cl >= lines.length) return;

    final painter = getOrCreateLinePainter(cl, lines[cl]);
    if (painter == null) return;

    final caretPrototype = Rect.fromLTWH(0, 0, 1.5, lineHeight);
    final caretOffset = painter.getOffsetForCaret(
      TextPosition(offset: _cursorColumn),
      caretPrototype,
    );

    final cursorX = textStartX + caretOffset.dx;
    final cursorY = padding.top + cl * lineHeight;

    final paint = Paint()
      ..color = textColor
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(cursorX, cursorY + 1),
      Offset(cursorX, cursorY + lineHeight - 1),
      paint,
    );
  }

  void _paintLineNumbers(
    Canvas canvas,
    Size size,
    List<String> lines,
    int startLine,
    int endLine,
  ) {
    for (int i = startLine; i < endLine && i < _totalLines; i++) {
      final y = padding.top + i * lineHeight;
      if (y + lineHeight < scrollOffset - lineHeight ||
          y > scrollOffset + viewportHeight + lineHeight) {
        continue;
      }

      final isCurrent = i == _cursorLine;
      if (isCurrent) {
        final bgPaint = Paint()
          ..color = lineNumberCurrentColor.withValues(alpha: 0.1);
        canvas.drawRect(Rect.fromLTWH(0, y, lineNumberWidth, lineHeight), bgPaint);
      }

      final numPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: lineNumberStyle.copyWith(
            color: isCurrent ? lineNumberCurrentColor : lineNumberColor,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      numPainter.layout(minWidth: lineNumberWidth - 8, maxWidth: lineNumberWidth - 8);
      numPainter.paint(canvas, Offset(0, y));
    }
  }

  @override
  bool shouldRepaint(covariant _EditorPainter old) => true;
}
