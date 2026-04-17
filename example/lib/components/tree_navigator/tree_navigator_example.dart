import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

class TreeNavigatorExamplePage extends StatefulWidget {
  const TreeNavigatorExamplePage({super.key});

  @override
  State<TreeNavigatorExamplePage> createState() =>
      _TreeNavigatorExamplePageState();
}

class _TreeNavigatorExamplePageState extends State<TreeNavigatorExamplePage> {
  late final UNavCntlr _navController;

  @override
  void initState() {
    super.initState();
    _navController = UNavCntlr();
  }

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('UTreeNavigator 示例'),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
      ),
      body: UTreeNavigator(
        cntlr: _navController,
        initialPath: '/home',
        onPopRoot: Navigator.of(context).pop,
        widgetBuilder: (path) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('当前路径: $path', style: const TextStyle(fontSize: 18)),
                SizedBox(height: theme.spacingMedium),
                Wrap(
                  spacing: theme.spacingSmall,
                  children: [
                    UButton(
                      child: const Text('子目录 A'),
                      onPressed: () => _navController.push('$path/A'),
                    ),
                    UButton(
                      child: const Text('子目录 B'),
                      onPressed: () => _navController.push('$path/B'),
                    ),
                  ],
                ),
                SizedBox(height: theme.spacingMedium),
                Text(
                  'canPop: ${_navController.canPop()}, canForward: ${_navController.canForward()}',
                  style: TextStyle(color: theme.secondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
