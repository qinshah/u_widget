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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(theme.spacingMedium),
            child: Row(
              children: [
                Expanded(
                  child: _buildOptionChip(
                    theme,
                    '显示行号',
                    Icons.format_list_numbered,
                    null,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: UTextEditor(cntlr: _controller)),
        ],
      ),
    );
  }

  Widget _buildOptionChip(
    UThemeData theme,
    String label,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(theme.borderRadiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.primary),
          SizedBox(width: theme.spacingSmall),
          Text(label, style: TextStyle(color: theme.onSurface)),
        ],
      ),
    );
  }

  void _loadSampleCode() {
    setState(() {
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
    });
  }
}