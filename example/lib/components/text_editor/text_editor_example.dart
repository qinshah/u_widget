import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

class TextEditorExamplePage extends StatefulWidget {
  const TextEditorExamplePage({super.key});

  @override
  State<TextEditorExamplePage> createState() => _TextEditorExamplePageState();
}

class _TextEditorExamplePageState extends State<TextEditorExamplePage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = 'void main() {\n'
        '  print("Hello, World!");\n'
        '}\n'
        '\n'
        'class Person {\n'
        '  final String name;\n'
        '  final int age;\n'
        '\n'
        '  const Person({\n'
        '    required this.name,\n'
        '    required this.age,\n'
        '  });\n'
        '\n'
        '  void greet() {\n'
        '    print("Hi, I\'m \$name, \$age years old.");\n'
        '  }\n'
        '}\n';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('UTextEditor 示例'),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: '加载代码示例',
            onPressed: _loadSampleCode,
          ),
        ],
      ),
      body: UTextEditor(
        cntlr: _controller,
        onChanged: (_) {},
      ),
    );
  }

  void _loadSampleCode() {
    _controller.text = 'import ' "dart:math';\n"
        '\n'
        'void main() {\n'
        '  final numbers = [1, 2, 3, 4, 5];\n'
        '  final result = numbers\n'
        '      .map((n) => n * n)\n'
        '      .where((n) => n > 10)\n'
        '      .toList();\n'
        '\n'
        '  print(result);\n'
        '\n'
        '  final random = Random();\n'
        '  for (var i = 0; i < 5; i++) {\n'
        '    print("随机数: \${random.nextInt(100)}");\n'
        '  }\n'
        '}\n';
  }
}