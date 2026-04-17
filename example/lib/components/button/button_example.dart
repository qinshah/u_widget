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
            '按钮变体',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          Wrap(
            spacing: theme.spacingMedium,
            runSpacing: theme.spacingMedium,
            children: [
              UButton(
                variant: UButtonVariant.filled,
                child: const Text('Filled'),
              ),
              UButton(
                variant: UButtonVariant.outlined,
                child: const Text('Outlined'),
              ),
              UButton(variant: UButtonVariant.text, child: const Text('Text')),
              UButton(
                variant: UButtonVariant.ghost,
                child: const Text('Ghost'),
              ),
            ],
          ),
          SizedBox(height: theme.spacingLarge),
          Text(
            '按钮尺寸',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          Wrap(
            spacing: theme.spacingMedium,
            children: [
              UButton(size: UButtonSize.small, child: const Text('Small')),
              UButton(size: UButtonSize.medium, child: const Text('Medium')),
              UButton(size: UButtonSize.large, child: const Text('Large')),
            ],
          ),
          SizedBox(height: theme.spacingLarge),
          Text(
            '自定义颜色',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          Wrap(
            spacing: theme.spacingMedium,
            children: [
              UButton(child: const Text('Blue'), color: Colors.blue),
              UButton(child: const Text('Orange'), color: Colors.orange),
              UButton(child: const Text('Purple'), color: Colors.purple),
            ],
          ),
          SizedBox(height: theme.spacingLarge),
          Text(
            '交互反馈',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          UButton(
            child: const Text('点击我'),
            onTap: () => _showSnackBar(context, '按钮被点击'),
            onLongPress: () => _showSnackBar(context, '按钮被长按'),
          ),
          SizedBox(height: theme.spacingMedium),
          Text(
            '禁用状态',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacingMedium),
          UButton(
            child: const Text('禁用按钮'),
            enabled: false,
            onTap: () => _showSnackBar(context, '按钮被点击'),
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
