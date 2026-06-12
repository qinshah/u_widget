part of '../u_text_editor.dart';

// ===================== Editor Painter =====================

class _EditorPainter extends CustomPainter {
  final TextEditingController controller;
  final List<int> lineStarts;
  final ScrollController scrollController;
  final ValueNotifier<bool> cursorBlinkNotifier;
  final bool hasFocus;
  final TextStyle textStyle;
  final double lineHeight;
  final EdgeInsets padding;
  final double viewportHeight;
  final Color textColor;
  final bool showLineNumbers;
  final double lineNumberWidth;
  final TextStyle lineNumberStyle;
  final Color lineNumberCurrentColor;
  final Color lineNumberColor;
  final double textWidth;
  final TextPainter? Function(int lineIndex, String lineText)
      getOrCreateLinePainter;
  final Listenable repaint;

  final Map<int, TextPainter> _lineNumberCache = {};
  int _lastCursorLine = -1;
  int _lastTotalLines = -1;

  _EditorPainter({
    required this.controller,
    required this.lineStarts,
    required this.scrollController,
    required this.cursorBlinkNotifier,
    required this.hasFocus,
    required this.textStyle,
    required this.lineHeight,
    required this.padding,
    required this.viewportHeight,
    required this.textColor,
    required this.showLineNumbers,
    required this.lineNumberWidth,
    required this.lineNumberStyle,
    required this.lineNumberCurrentColor,
    required this.lineNumberColor,
    required this.textWidth,
    required this.getOrCreateLinePainter,
    required this.repaint,
  }) : super(repaint: repaint);

  bool get _cursorVisible => hasFocus && cursorBlinkNotifier.value;

  double get _scrollOffset =>
      scrollController.hasClients ? scrollController.offset : 0.0;

  int get _cursorLine {
    final offset = controller.selection.baseOffset;
    if (offset < 0 || lineStarts.isEmpty) return 0;
    int lo = 0, hi = lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  int get _cursorColumn {
    final offset = controller.selection.baseOffset;
    if (offset <= 0 || lineStarts.isEmpty) return 0;
    return offset - lineStarts[_cursorLine];
  }

  String _lineText(int i) {
    final text = controller.text;
    final start = lineStarts[i];
    final end =
        i < lineStarts.length - 1 ? lineStarts[i + 1] - 1 : text.length;
    if (start > end) return '';
    return text.substring(start, end);
  }

  int _lineIndexAt(int offset) {
    if (offset < 0 || lineStarts.isEmpty) return 0;
    int lo = 0, hi = lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final so = _scrollOffset;
    final startLine = math.max(0, (so / lineHeight).floor() - 2);
    final endLine = math.min(
      lineStarts.length,
      ((so + viewportHeight) / lineHeight).ceil() + 2,
    );

    final textStartX =
        padding.left + (showLineNumbers ? lineNumberWidth : 0);

    if (showLineNumbers) {
      _paintLineNumbers(canvas, startLine, endLine);
    }

    _paintSelection(canvas, textStartX);

    for (int i = startLine; i < endLine; i++) {
      final y = padding.top + i * lineHeight;
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(textStartX, y, textWidth, lineHeight + 1),
      );
      final lineText = _lineText(i);
      final painter = getOrCreateLinePainter(i, lineText);
      if (painter != null) {
        painter.paint(canvas, Offset(textStartX, y));
      }
      canvas.restore();
    }

    _paintComposingHighlight(canvas, textStartX);

    if (_cursorVisible) {
      _paintCursor(canvas, textStartX);
    }
  }

  void _paintSelection(Canvas canvas, double textStartX) {
    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final text = controller.text;
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    if (start == end) return;

    final highlightPaint = Paint()..color = const Color(0x660000FF);

    final startLine = _lineIndexAt(start);
    final endLine = _lineIndexAt(end);

    for (int lineIdx = startLine; lineIdx <= endLine; lineIdx++) {
      final lineText = _lineText(lineIdx);
      final painter = getOrCreateLinePainter(lineIdx, lineText);
      if (painter == null) continue;

      int selStart = 0;
      int selEnd = lineText.length;

      if (lineIdx == startLine) {
        selStart = start - lineStarts[lineIdx];
      }
      if (lineIdx == endLine) {
        selEnd = end - lineStarts[lineIdx];
      }
      selStart = selStart.clamp(0, lineText.length);
      selEnd = selEnd.clamp(0, lineText.length);
      if (selStart >= selEnd) continue;

      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: selStart, extentOffset: selEnd),
      );
      for (final box in boxes) {
        canvas.drawRect(
          Rect.fromLTRB(
            textStartX + box.left,
            padding.top + lineIdx * lineHeight + box.top,
            textStartX + box.right,
            padding.top + lineIdx * lineHeight + box.bottom,
          ),
          highlightPaint,
        );
      }
    }
  }

  void _paintComposingHighlight(Canvas canvas, double textStartX) {
    final composing = controller.value.composing;
    if (!composing.isValid || composing.isCollapsed) return;

    final text = controller.text;
    final start = composing.start.clamp(0, text.length);
    final end = composing.end.clamp(0, text.length);
    if (start == end) return;

    final paint = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final startLine = _lineIndexAt(start);
    final endLine = _lineIndexAt(end);

    for (int lineIdx = startLine; lineIdx <= endLine; lineIdx++) {
      final lineText = _lineText(lineIdx);
      final painter = getOrCreateLinePainter(lineIdx, lineText);
      if (painter == null) continue;

      int compStart = 0;
      int compEnd = lineText.length;
      if (lineIdx == startLine) compStart = start - lineStarts[lineIdx];
      if (lineIdx == endLine) compEnd = end - lineStarts[lineIdx];
      compStart = compStart.clamp(0, lineText.length);
      compEnd = compEnd.clamp(0, lineText.length);
      if (compStart >= compEnd) continue;

      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: compStart, extentOffset: compEnd),
      );
      for (final box in boxes) {
        final rect = Rect.fromLTRB(
          textStartX + box.left,
          padding.top + lineIdx * lineHeight + box.bottom - 2,
          textStartX + box.right,
          padding.top + lineIdx * lineHeight + box.bottom,
        );
        canvas.drawRect(rect, paint);
      }
    }
  }

  void _paintCursor(Canvas canvas, double textStartX) {
    final cl = _cursorLine;
    if (cl >= lineStarts.length) return;

    final lineText = _lineText(cl);
    final painter = getOrCreateLinePainter(cl, lineText);
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

  void _paintLineNumbers(Canvas canvas, int startLine, int endLine) {
    final cl = _cursorLine;
    final total = lineStarts.length;
    if (cl != _lastCursorLine || total != _lastTotalLines) {
      for (final p in _lineNumberCache.values) {
        p.dispose();
      }
      _lineNumberCache.clear();
      _lastCursorLine = cl;
      _lastTotalLines = total;
    }

    for (int i = startLine; i < endLine && i < total; i++) {
      final y = padding.top + i * lineHeight;
      if (y + lineHeight < _scrollOffset - lineHeight ||
          y > _scrollOffset + viewportHeight + lineHeight) {
        continue;
      }

      final isCurrent = i == cl;
      if (isCurrent) {
        final bgPaint = Paint()
          ..color = lineNumberCurrentColor.withValues(alpha: 0.1);
        canvas.drawRect(
          Rect.fromLTWH(0, y, lineNumberWidth, lineHeight),
          bgPaint,
        );
      }

      TextPainter? numPainter = _lineNumberCache[i];
      if (numPainter == null) {
        numPainter = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
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
        _lineNumberCache[i] = numPainter;
      }
      numPainter.paint(canvas, Offset(0, y));
    }
  }

  @override
  bool shouldRepaint(covariant _EditorPainter old) => true;
}