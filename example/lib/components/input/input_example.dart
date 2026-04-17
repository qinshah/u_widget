import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

class InputExamplePage extends StatefulWidget {
  const InputExamplePage({super.key});

  @override
  State<InputExamplePage> createState() => _InputExamplePageState();
}

class _InputExamplePageState extends State<InputExamplePage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = '初始文本';
  }

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('UInput 示例'),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
      ),
      body: ListView(
        padding: EdgeInsets.all(theme.spacingMedium),
        children: [
          Text(
            '基本输入框',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          const UInput(hintText: '请输入文本'),
          SizedBox(height: theme.spacingLarge),
          Text(
            '带清除按钮',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          UInput(hintText: '输入后可清除', showClearIcon: true, cntlr: _controller),
          SizedBox(height: theme.spacingLarge),
          Text(
            '密码输入框',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          const UInput(hintText: '请输入密码', type: UInputType.password),
          SizedBox(height: theme.spacingLarge),
          Text(
            '数字输入框',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          const UInput(hintText: '请输入数字', type: UInputType.number),
          SizedBox(height: theme.spacingLarge),
          Text(
            '带前缀/后缀图标',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          const UInput(
            hintText: '搜索',
            prefix: Icon(Icons.search),
            suffix: Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}
