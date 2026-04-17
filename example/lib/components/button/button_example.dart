import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

class ButtonExamplePage extends StatelessWidget {
  const ButtonExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('UButton 示例'),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
      ),
      body: ListView(
        padding: EdgeInsets.all(theme.spacingMedium),
        children: [
          Text(
            '按钮类型',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          Wrap(
            spacing: theme.spacingMedium,
            runSpacing: theme.spacingMedium,
            children: [
              UButton(
                backgroundColor: Colors.transparent,
                borderColor: Colors.transparent,
                child: const Text('文字按钮'),
              ),
              UButton(
                child: const Text('默认样式'),
              ),
              UButton(
                backgroundColor: Colors.transparent,
                child: const Text('线框按钮'),
              ),
            ],
          ),
          SizedBox(height: theme.spacingLarge),
          Text(
            '禁用状态',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          Wrap(
            spacing: theme.spacingMedium,
            runSpacing: theme.spacingMedium,
            children: [
              UButton(
                disable: false,
                backgroundColor: Colors.transparent,
                borderColor: Colors.transparent,
                onPressed: () {},
                child: const Text('文字按钮（禁用）'),
              ),
              UButton(disable: false, child: const Text('默认样式（禁用）')),
              UButton(
                disable: false,
                backgroundColor: Colors.transparent,
                child: const Text('线框按钮（禁用）'),
              ),
            ],
          ),
          SizedBox(height: theme.spacingLarge),
          Text(
            '全宽内容居中',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          UButton(child: Center(child: const Text('居中'))),
          SizedBox(height: theme.spacingLarge),
          Text(
            '事件交互',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          UButton(
            onPressed: () => _showSnackBar(context, '按钮被点击'),
            onLongPressed: () => _showSnackBar(context, '按钮被长按'),
            child: Center(child: const Text('点击或长按我')),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
