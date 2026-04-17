import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

class ScrollPickerExamplePage extends StatefulWidget {
  const ScrollPickerExamplePage({super.key});

  @override
  State<ScrollPickerExamplePage> createState() =>
      _ScrollPickerExamplePageState();
}

class _ScrollPickerExamplePageState extends State<ScrollPickerExamplePage> {
  String _selectedValue = '';

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    final items = [
      UScrollPickerItem<String>(value: '选项1'),
      UScrollPickerItem<String>(value: '选项2'),
      UScrollPickerItem<String>(value: '选项3'),
      UScrollPickerItem<String>(
        value: '选项4',
        children: [
          UScrollPickerItem<String>(value: '子选项4-1'),
          UScrollPickerItem<String>(value: '子选项4-2'),
          UScrollPickerItem<String>(value: '子选项4-3'),
        ],
      ),
      UScrollPickerItem<String>(value: '选项5'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('UScrollPicker 示例'),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: UScrollPicker<String>(
                items: items,
                columns: 2,
                onChanged: (values) {
                  setState(() {
                    _selectedValue = values.join(' - ');
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(theme.spacingMedium),
            child: Text(
              '选中的值: $_selectedValue',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
