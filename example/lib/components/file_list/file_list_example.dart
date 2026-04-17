import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

class FileListExamplePage extends StatelessWidget {
  const FileListExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    final files = [
      UFileItem(
        name: 'Documents',
        path: '/Documents',
        type: 'directory',
        modified: DateTime.now(),
      ),
      UFileItem(
        name: 'Downloads',
        path: '/Downloads',
        type: 'directory',
        modified: DateTime.now(),
      ),
      UFileItem(
        name: 'example.txt',
        path: '/example.txt',
        type: 'file',
        size: 1024,
        modified: DateTime.now(),
      ),
      UFileItem(
        name: 'photo.png',
        path: '/photo.png',
        type: 'file',
        size: 204800,
        modified: DateTime.now(),
      ),
      UFileItem(
        name: 'report.pdf',
        path: '/report.pdf',
        type: 'file',
        size: 512000,
        modified: DateTime.now(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('UFileListWidget 示例'),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
      ),
      body: UFileListWidget(
        files: files,
        onItemTap: (file) => _showSnackBar(context, '点击: ${file.name}'),
        onShowMenu: (file, offset) =>
            _showSnackBar(context, '显示菜单: ${file.name}'),
        onItemDoubleTap: (file) => _showSnackBar(context, '双击: ${file.name}'),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
