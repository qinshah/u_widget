import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

class NavigationBarExamplePage extends StatefulWidget {
  const NavigationBarExamplePage({super.key});

  @override
  State<NavigationBarExamplePage> createState() =>
      _NavigationBarExamplePageState();
}

class _NavigationBarExamplePageState extends State<NavigationBarExamplePage> {
  String _currentPath = '/Users/Documents';
  final List<String> _history = [];
  final List<String> _forwardHistory = [];

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('UNavigationBar 示例'),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(theme.spacingMedium),
            child: UNavigationBar(
              currentPath: _currentPath,
              onHome: () => _navigateTo('/'),
              onBack: () => _goBack(),
              onForward: () => _goForward(),
              onUp: () => _goUp(),
              onRefresh: () => _refresh(),
              canGoBack: _history.isNotEmpty,
              canGoForward: _forwardHistory.isNotEmpty,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '当前路径: $_currentPath',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(String path) {
    setState(() {
      if (_currentPath != path) {
        _history.add(_currentPath);
        _forwardHistory.clear();
        _currentPath = path;
      }
    });
  }

  void _goBack() {
    if (_history.isNotEmpty) {
      setState(() {
        _forwardHistory.add(_currentPath);
        _currentPath = _history.removeLast();
      });
    }
  }

  void _goForward() {
    if (_forwardHistory.isNotEmpty) {
      setState(() {
        _history.add(_currentPath);
        _currentPath = _forwardHistory.removeLast();
      });
    }
  }

  void _goUp() {
    if (_currentPath.isNotEmpty && _currentPath != '/') {
      final parts = _currentPath.split('/');
      if (parts.length > 1) {
        parts.removeLast();
        _navigateTo(parts.join('/'));
      }
    }
  }

  void _refresh() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('刷新当前目录')));
  }
}