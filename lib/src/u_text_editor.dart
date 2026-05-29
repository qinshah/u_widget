import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';

class UTextEditor extends StatefulWidget {
  const UTextEditor({
    super.key,
    this.cntlr,
    this.showLineNumbers = true,
    this.showStatusBar = true,
    this.lineNumberWidth = 48.0,
    this.fontSize = 14.0,
    this.lineHeight = 1.4,
    this.padding,
  });

  final TextEditingController? cntlr;
  final bool showLineNumbers;
  final bool showStatusBar;
  final double lineNumberWidth;
  final double fontSize;
  final double lineHeight;
  final EdgeInsets? padding;

  @override
  State<UTextEditor> createState() => _UTextEditorState();
}

class _UTextEditorState extends State<UTextEditor> {
  late final TextEditingController _cntlr;
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _lineNumberScrollController = ScrollController();
  bool _syncingScroll = false;
  int _cursorLine = 1;
  int _cursorColumn = 1;

  @override
  void initState() {
    super.initState();
    _cntlr = widget.cntlr ?? TextEditingController();
    _cntlr.addListener(_onTextChanged);
    _editorScrollController.addListener(_onEditorScroll);
    _lineNumberScrollController.addListener(_onLineNumberScroll);
  }

  @override
  void dispose() {
    if (widget.cntlr == null) {
      _cntlr.dispose();
    } else {
      _cntlr.removeListener(_onTextChanged);
    }
    _editorScrollController.removeListener(_onEditorScroll);
    _lineNumberScrollController.removeListener(_onLineNumberScroll);
    _editorScrollController.dispose();
    _lineNumberScrollController.dispose();
    super.dispose();
  }

  void _onEditorScroll() {
    if (_syncingScroll) return;
    _syncingScroll = true;
    if (_lineNumberScrollController.hasClients) {
      _lineNumberScrollController.jumpTo(
        _editorScrollController.offset,
      );
    }
    _syncingScroll = false;
  }

  void _onLineNumberScroll() {
    if (_syncingScroll) return;
    _syncingScroll = true;
    if (_editorScrollController.hasClients) {
      _editorScrollController.jumpTo(
        _lineNumberScrollController.offset,
      );
    }
    _syncingScroll = false;
  }

  void _onTextChanged() {
    _updateCursorPosition();
    setState(() {});
  }

  void _updateCursorPosition() {
    final selection = _cntlr.selection;
    if (!selection.isValid) return;

    final cursorOffset = selection.baseOffset;
    final text = _cntlr.text;

    if (cursorOffset < 0 || cursorOffset > text.length) return;

    int line = 1;
    int col = 1;
    for (int i = 0; i < cursorOffset; i++) {
      if (text[i] == '\n') {
        line++;
        col = 1;
      } else {
        col++;
      }
    }
    _cursorLine = line;
    _cursorColumn = col;
  }

  int get _totalLines {
    if (_cntlr.text.isEmpty) return 1;
    return '\n'.allMatches(_cntlr.text).length + 1;
  }

  double get _lineHeight => widget.fontSize * widget.lineHeight;

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    final textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      color: theme.onSurface,
    );
    final lineNumberStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      color: theme.secondary,
    );

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showLineNumbers)
                _buildLineNumberColumn(theme, lineNumberStyle),
              Expanded(child: _buildEditor(textStyle)),
            ],
          ),
        ),
        if (widget.showStatusBar) _buildStatusBar(theme),
      ],
    );
  }

  Widget _buildLineNumberColumn(UThemeData theme, TextStyle style) {
    final editorPadding =
        widget.padding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    return Container(
      width: widget.lineNumberWidth,
      color: theme.surface,
      child: ListView.builder(
        controller: _lineNumberScrollController,
        padding: EdgeInsets.only(
          top: editorPadding.top,
          bottom: editorPadding.bottom,
        ),
        itemExtent: _lineHeight,
        itemCount: _totalLines,
        itemBuilder: (context, index) {
          final lineNum = index + 1;
          final isCurrentLine = lineNum == _cursorLine;
          return Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            color: isCurrentLine ? theme.primary.withValues(alpha: 0.1) : null,
            child: Text(
              '$lineNum',
              style: style.copyWith(
                color:
                    isCurrentLine ? theme.primary : theme.secondary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditor(TextStyle style) {
    final editorPadding =
        widget.padding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    return TextField(
      controller: _cntlr,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: TextInputType.multiline,
      scrollController: _editorScrollController,
      style: style,
      decoration: InputDecoration(
        contentPadding: editorPadding,
        border: InputBorder.none,
        isDense: true,
      ),
    );
  }

  Widget _buildStatusBar(UThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide()),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: theme.secondary,
        ),
        child: Row(
          children: [
            Text('行 $_cursorLine, 列 $_cursorColumn'),
            const Spacer(),
            Text('共 $_totalLines 行'),
          ],
        ),
      ),
    );
  }
}