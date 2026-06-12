part of '../u_text_editor.dart';

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