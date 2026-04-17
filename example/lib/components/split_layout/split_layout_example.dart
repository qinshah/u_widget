import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

class SplitLayoutExamplePage extends StatelessWidget {
  const SplitLayoutExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('USplitLayout 示例'),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
      ),
      body: USplitLayout(
        direction: Axis.horizontal,
        panels: [
          USplitPanel(
            child: Container(
              color: theme.primary.withAlpha(26),
              child: Center(
                child: Text('面板 1', style: TextStyle(color: theme.primary)),
              ),
            ),
            flex: 1,
          ),
          USplitPanel(
            child: Container(
              color: theme.secondary.withAlpha(26),
              child: Center(
                child: Text('面板 2', style: TextStyle(color: theme.secondary)),
              ),
            ),
            flex: 1,
          ),
          USplitPanel(
            child: Container(
              color: theme.error.withAlpha(26),
              child: Center(
                child: Text('面板 3', style: TextStyle(color: theme.error)),
              ),
            ),
            flex: 1,
          ),
        ],
      ),
    );
  }
}
