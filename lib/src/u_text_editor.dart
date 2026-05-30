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
    implements TextInputClient {
  late final TextEditingController _cntlr;
  late final FocusNode _focusNode;
  final ScrollController _scrollController = ScrollController();

  TextInputConnection? _inputConnection;
  Timer? _cursorTimer;
  bool _cursorVisible = true;

  double _viewportHeight = 0;
  double _viewportWidth = 0;
  double _lineHeightPx = 0;

  late ui.TextStyle _uiTextStyle;
  late TextStyle _lineNumberStyle;
  Color _textColor = Colors.black;
  Color _lineNumberColor = Colors.grey;
  Color _lineNumberCurrentColor = Colors.blue;
  Color _surfaceColor = Colors.white;

  final Map<int, ui.Paragraph> _paragraphCache = {};

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

  @override
  void initState() {
    super.initState();
    _cntlr = widget.cntlr ?? TextEditingController(text: widget.initialText);
    _focusNode = widget.focusNode ?? FocusNode();
    _cntlr.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChange);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = UTheme.of(context);
    _textColor = theme.onSurface;
    _lineNumberColor = theme.secondary;
    _lineNumberCurrentColor = theme.primary;
    _surfaceColor = theme.surface;
    _lineHeightPx = widget.fontSize * widget.lineHeight;
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
  void dispose() {
    _cntlr.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocusChange);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _closeInputConnection();
    _stopCursorBlink();
    _clearParagraphCache();
    if (widget.cntlr == null) _cntlr.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _clearParagraphCache() {
    for (final p in _paragraphCache.values) {
      p.dispose();
    }
    _paragraphCache.clear();
  }

  // ===================== Controller =====================

  void _onControllerChanged() {
    _clearParagraphCache();
    widget.onChanged?.call(_cntlr.text);
    if (mounted) setState(() {});
  }

  // ===================== 光标 =====================

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

  void _startCursorBlink() {
    _cursorVisible = true;
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(
      const Duration(milliseconds: 530),
      (_) {
        if (mounted) setState(() => _cursorVisible = !_cursorVisible);
      },
    );
  }

  void _stopCursorBlink() {
    _cursorTimer?.cancel();
    _cursorTimer = null;
  }

  void _restartCursorBlink() {
    if (!mounted) return;
    _cursorVisible = true;
    _startCursorBlink();
  }

  // ===================== 输入 =====================

  void _openInputConnection() {
    if (_inputConnection != null && _inputConnection!.attached) return;
    _inputConnection = TextInput.attach(
      this,
      const TextInputConfiguration(
        inputType: TextInputType.multiline,
        inputAction: TextInputAction.newline,
        enableSuggestions: false,
        autocorrect: false,
      ),
    );
    _inputConnection!.show();
    _updateInputConnection();
  }

  void _closeInputConnection() {
    _inputConnection?.close();
    _inputConnection = null;
  }

  void _updateInputConnection() {
    if (_inputConnection == null || !_inputConnection!.attached) return;
    _inputConnection!.setEditingState(_cntlr.value);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _openInputConnection();
      _startCursorBlink();
    } else {
      _closeInputConnection();
      _stopCursorBlink();
      if (mounted) setState(() {});
    }
  }

  // ===================== TextInputClient =====================

  @override
  TextEditingValue? get currentTextEditingValue => _cntlr.value;

  @override
  void updateEditingValue(TextEditingValue value) {
    final oldValue = _cntlr.value;
    if (value.text != oldValue.text || value.composing != oldValue.composing) {
      _cntlr.value = value;
    } else if (value.selection != oldValue.selection) {
      _cntlr.selection = value.selection;
    }
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
    _inputConnection = null;
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
  void didChangeInputControl(TextInputControl? old, TextInputControl? now) {}

  @override
  void insertContent(KeyboardInsertedContent content) {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void performSelector(String selectorName) {}

  // ===================== 滚动 =====================

  void _onScroll() {
    if (!mounted) return;
    setState(() {});
  }

  void _ensureCursorVisible() {
    if (!_scrollController.hasClients) return;
    final cursorY = _cursorLine * _lineHeightPx;
    final visibleTop = _scrollController.offset;
    final visibleBottom = visibleTop + _viewportHeight;

    if (cursorY < visibleTop) {
      _scrollController.jumpTo(cursorY);
    } else if (cursorY + _lineHeightPx > visibleBottom) {
      _scrollController.jumpTo(
        cursorY + _lineHeightPx - _viewportHeight + _padding.vertical,
      );
    }
  }

  // ===================== 手势 =====================

  void _onTapDown(TapDownDetails details) {
    _focusNode.requestFocus();
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
    _updateInputConnection();
    _restartCursorBlink();
  }

  (int line, int column) _offsetToPosition(Offset offset) {
    double dx = offset.dx - _padding.left;
    if (widget.showLineNumbers) dx -= widget.lineNumberWidth;
    double dy = offset.dy - _padding.top + _scrollController.offset;

    final lines = _cntlr.text.split('\n');
    int line = (dy / _lineHeightPx).floor().clamp(0, lines.length - 1);

    final paragraph = _getParagraph(line);
    if (paragraph == null) return (line, 0);

    final position = paragraph.getPositionForOffset(Offset(dx, 0));
    int column = position.offset.clamp(0, lines[line].length);
    return (line, column);
  }

  ui.Paragraph? _getParagraph(int lineIndex) {
    if (_paragraphCache.containsKey(lineIndex)) {
      return _paragraphCache[lineIndex]!;
    }
    final lines = _cntlr.text.split('\n');
    if (lineIndex >= lines.length) return null;

    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '',
      ),
    );
    builder.pushStyle(_uiTextStyle);
    builder.addText(lines[lineIndex]);
    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: _textWidth));
    _paragraphCache[lineIndex] = paragraph;
    return paragraph;
  }

  // ===================== 键盘 =====================

  void _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    final logical = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    final oldSelection = _cntlr.selection;
    final oldOffset = oldSelection.baseOffset;
    final text = _cntlr.text;

    if (logical == LogicalKeyboardKey.arrowLeft) {
      if (isCtrl) {
        _moveCursorWordLeft(oldOffset);
      } else {
        _cntlr.selection = TextSelection.collapsed(
          offset: math.max(0, oldOffset - 1),
        );
      }
      _updateInputConnection();
      _restartCursorBlink();
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
      _updateInputConnection();
      _restartCursorBlink();
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
        newOffset = math.max(0, newOffset);
        _cntlr.selection = TextSelection.collapsed(offset: newOffset);
      }
      _updateInputConnection();
      _restartCursorBlink();
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
        newOffset = math.min(text.length, newOffset);
        _cntlr.selection = TextSelection.collapsed(offset: newOffset);
      }
      _updateInputConnection();
      _restartCursorBlink();
      _ensureCursorVisible();
      return;
    }
    if (logical == LogicalKeyboardKey.home) {
      final lineStart = oldOffset - _cursorColumn;
      _cntlr.selection = TextSelection.collapsed(offset: lineStart);
      _updateInputConnection();
      _restartCursorBlink();
      return;
    }
    if (logical == LogicalKeyboardKey.end) {
      final lines = text.split('\n');
      final lineEnd = oldOffset - _cursorColumn + lines[_cursorLine].length;
      _cntlr.selection = TextSelection.collapsed(offset: lineEnd);
      _updateInputConnection();
      _restartCursorBlink();
      return;
    }
    if (logical == LogicalKeyboardKey.backspace || logical == LogicalKeyboardKey.delete) {
      final isForward = logical == LogicalKeyboardKey.delete;
      _handleDelete(oldSelection, isForward);
      _updateInputConnection();
      _restartCursorBlink();
      return;
    }
    if (logical == LogicalKeyboardKey.enter || logical == LogicalKeyboardKey.numpadEnter) {
      final value = _cntlr.value;
      final offset = value.selection.baseOffset;
      final text = value.text;
      final result = TextEditingValue(
        text: '${text.substring(0, offset)}\n${text.substring(offset)}',
        selection: TextSelection.collapsed(offset: offset + 1),
      );
      _cntlr.value = result;
      _updateInputConnection();
      _restartCursorBlink();
      _ensureCursorVisible();
      return;
    }
    if (logical == LogicalKeyboardKey.tab) {
      final value = _cntlr.value;
      final offset = value.selection.baseOffset;
      final text = value.text;
      final result = TextEditingValue(
        text: '${text.substring(0, offset)}  ${text.substring(offset)}',
        selection: TextSelection.collapsed(offset: offset + 2),
      );
      _cntlr.value = result;
      _updateInputConnection();
      _restartCursorBlink();
      _ensureCursorVisible();
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

    final character = event.character;
    if (character != null && character.isNotEmpty && !isCtrl) {
      final value = _cntlr.value;
      final offset = value.selection.baseOffset;
      final text = value.text;
      final result = TextEditingValue(
        text: '${text.substring(0, offset)}$character${text.substring(offset)}',
        selection: TextSelection.collapsed(offset: offset + character.length),
      );
      _cntlr.value = result;
      _updateInputConnection();
      _restartCursorBlink();
      _ensureCursorVisible();
    }
  }

  void _handleDelete(TextSelection selection, bool forward) {
    final text = _cntlr.text;
    final offset = selection.baseOffset;
    if (forward) {
      if (offset >= text.length) return;
      final result = TextEditingValue(
        text: text.substring(0, offset) + text.substring(offset + 1),
        selection: TextSelection.collapsed(offset: offset),
      );
      _cntlr.value = result;
    } else {
      if (offset <= 0) return;
      final result = TextEditingValue(
        text: text.substring(0, offset - 1) + text.substring(offset),
        selection: TextSelection.collapsed(offset: offset - 1),
      );
      _cntlr.value = result;
    }
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
    _updateInputConnection();
    _restartCursorBlink();
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
    _updateInputConnection();
    _restartCursorBlink();
  }

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: _cntlr.text));
  }

  void _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    final value = _cntlr.value;
    final offset = value.selection.baseOffset;
    final text = value.text;
    final pasteText = data!.text!;
    final result = TextEditingValue(
      text: '${text.substring(0, offset)}$pasteText${text.substring(offset)}',
      selection: TextSelection.collapsed(offset: offset + pasteText.length),
    );
    _cntlr.value = result;
    _updateInputConnection();
    _restartCursorBlink();
  }

  // ===================== Build =====================

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
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
                          cursorVisible: _cursorVisible && _focusNode.hasFocus,
                          textStyle: _uiTextStyle,
                          lineHeight: _lineHeightPx,
                          padding: _padding,
                          scrollOffset:_scrollController.hasClients? _scrollController.offset: 0,
                          viewportHeight: _viewportHeight,
                          textColor: _textColor,
                          showLineNumbers: widget.showLineNumbers,
                          lineNumberWidth: widget.lineNumberWidth,
                          lineNumberStyle: _lineNumberStyle,
                          lineNumberCurrentColor: _lineNumberCurrentColor,
                          lineNumberColor: _lineNumberColor,
                          surfaceColor: _surfaceColor,
                          paragraphCache: _paragraphCache,
                          textWidth: _textWidth,
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

// ===================== Editor Painter =====================

class _EditorPainter extends CustomPainter {
  final TextEditingController controller;
  final bool cursorVisible;
  final ui.TextStyle textStyle;
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
  final Color surfaceColor;
  final Map<int, ui.Paragraph> paragraphCache;
  final double textWidth;

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
    required this.surfaceColor,
    required this.paragraphCache,
    required this.textWidth,
  });

  int get _totalLines {
    final text = controller.text;
    if (text.isEmpty) return 1;
    return '\n'.allMatches(text).length + 1;
  }

  int get _cursorLine {
    final offset = controller.selection.baseOffset;
    if (offset <= 0) return 0;
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
    final lines = controller.text.isEmpty
        ? <String>['']
        : controller.text.split('\n');
    final startLine = math.max(0, (scrollOffset / lineHeight).floor() - 2);
    final endLine = math.min(
      lines.length,
      ((scrollOffset + viewportHeight) / lineHeight).ceil() + 2,
    );

    final textStartX = padding.left + (showLineNumbers ? lineNumberWidth : 0);

    // 画行号
    if (showLineNumbers) {
      _paintLineNumbers(canvas, size, startLine, endLine);
    }

    // 画文本
    for (int i = startLine; i < endLine; i++) {
      final y = padding.top + i * lineHeight;
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(textStartX, y, textWidth, lineHeight + 1));

      final paragraph = _getParagraph(i, lines);
      if (paragraph != null) {
        canvas.drawParagraph(paragraph, Offset(textStartX, y));
      }
      canvas.restore();
    }

    // 画光标
    if (cursorVisible) {
      final cursorY = padding.top + _cursorLine * lineHeight;
      double cursorX = textStartX;

      if (_cursorColumn > 0) {
        final cursorLine = _cursorLine;
        if (cursorLine < lines.length) {
          final lineText = lines[cursorLine].substring(0, _cursorColumn);
          final p = _buildParagraph(lineText);
          cursorX += p.width;
          p.dispose();
        }
      }

      final cursorPaint = Paint()
        ..color = textColor
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(cursorX, cursorY + 1),
        Offset(cursorX, cursorY + lineHeight - 1),
        cursorPaint,
      );
    }
  }

  void _paintLineNumbers(
    Canvas canvas,
    Size size,
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

      final numText = '${i + 1}';
      final numPainter = TextPainter(
        text: TextSpan(
          text: numText,
          style: lineNumberStyle.copyWith(
            color: isCurrent ? lineNumberCurrentColor : lineNumberColor,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      numPainter.layout(
        minWidth: lineNumberWidth - 8,
        maxWidth: lineNumberWidth - 8,
      );
      numPainter.paint(canvas, Offset(0, y));
    }
  }

  ui.Paragraph? _getParagraph(int lineIndex, List<String> lines) {
    if (paragraphCache.containsKey(lineIndex)) return paragraphCache[lineIndex];
    if (lineIndex >= lines.length) return null;
    return _buildParagraph(lines[lineIndex], cacheIndex: lineIndex);
  }

  ui.Paragraph _buildParagraph(String text, {int? cacheIndex}) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '',
      ),
    );
    builder.pushStyle(textStyle);
    builder.addText(text);
    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: textWidth));
    if (cacheIndex != null) paragraphCache[cacheIndex] = paragraph;
    return paragraph;
  }

  @override
  bool shouldRepaint(covariant _EditorPainter old) {
    return true;
  }
}