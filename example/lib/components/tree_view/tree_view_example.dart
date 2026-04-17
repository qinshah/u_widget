import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

class TreeViewExamplePage extends StatelessWidget {
  const TreeViewExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    final root = UTreeNode<String>(
      data: 'Root',
      children: [
        UTreeNode<String>(
          data: 'Folder 1',
          children: [
            UTreeNode<String>(data: 'File 1.1'),
            UTreeNode<String>(data: 'File 1.2'),
          ],
        ),
        UTreeNode<String>(
          data: 'Folder 2',
          children: [
            UTreeNode<String>(data: 'File 2.1'),
            UTreeNode<String>(
              data: 'Subfolder 2.1',
              children: [UTreeNode<String>(data: 'File 2.1.1')],
            ),
          ],
        ),
        UTreeNode<String>(data: 'File 3'),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('UTreeView 示例'),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
      ),
      body: UTreeView<String>(
        rootNode: root,
        onNodeTap: (node) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('点击: ${node.data}')));
        },
        itemBuilder: (context, node) {
          return Row(
            children: [
              Icon(
                node.children.isNotEmpty
                    ? Icons.folder
                    : Icons.insert_drive_file,
                size: 20,
              ),
              SizedBox(width: theme.spacingSmall),
              Text(node.data.toString()),
            ],
          );
        },
      ),
    );
  }
}
