import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UWidget Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: UTheme(
        data: UThemeData.defaultTheme(),
        child: const DemoHomePage(),
      ),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('UWidget 示例'),
        backgroundColor: theme.surface,
        foregroundColor: theme.onSurface,
        elevation: theme.elevationSmall,
      ),
      body: ListView(
        padding: EdgeInsets.all(theme.spacingMedium),
        children: [
          _buildSection(
            context,
            '按钮组件 (UButton)',
            '支持多种类型的按钮组件',
            () => const ButtonExamplePage(),
          ),
          _buildSection(
            context,
            '输入框组件 (UInput)',
            '支持密码显示/隐藏、清除按钮等',
            () => const InputExamplePage(),
          ),
          _buildSection(
            context,
            '滚动选择器 (UScrollPicker)',
            '多列滚轮选择器',
            () => const ScrollPickerExamplePage(),
          ),
          _buildSection(
            context,
            '文件列表组件 (UFileListWidget)',
            '支持网格/列表视图切换',
            () => const FileListExamplePage(),
          ),
          _buildSection(
            context,
            '导航栏组件 (UNavigationBar)',
            '文件系统导航栏',
            () => const NavigationBarExamplePage(),
          ),
          _buildSection(
            context,
            '树形视图 (UTreeView)',
            '可展开的树形结构',
            () => const TreeViewExamplePage(),
          ),
          _buildSection(
            context,
            '分割布局 (USplitLayout)',
            '可拖拽调整大小的分割面板',
            () => const SplitLayoutExamplePage(),
          ),
          _buildSection(
            context,
            '树形导航 (UTreeNavigator)',
            '基于路径的导航控制器',
            () => const TreeNavigatorExamplePage(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String description,
    Widget Function() pageBuilder,
  ) {
    final theme = UTheme.of(context);
    return Card(
      elevation: theme.elevationSmall,
      margin: EdgeInsets.only(bottom: theme.spacingMedium),
      child: ListTile(
        contentPadding: EdgeInsets.all(theme.spacingMedium),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: theme.spacingTiny),
          child: Text(
            description,
            style: TextStyle(fontSize: 14, color: theme.secondary),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.secondary,
        ),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => pageBuilder()));
        },
      ),
    );
  }
}

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
      body: Padding(
        padding: EdgeInsets.all(theme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                UButton(child: const Text('Normal'), type: UButtonType.normal),
                UButton(
                  child: const Text('Success'),
                  type: UButtonType.success,
                ),
                UButton(
                  child: const Text('Warning'),
                  type: UButtonType.warning,
                ),
                UButton(child: const Text('Error'), type: UButtonType.error),
                UButton(child: const Text('Info'), type: UButtonType.info),
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
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

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
      body: Padding(
        padding: EdgeInsets.all(theme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
    );
  }
}

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
        onPopRoot: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已到达根目录')));
        },
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
                      onTap: () => _navController.push('$path/A'),
                    ),
                    UButton(
                      child: const Text('子目录 B'),
                      onTap: () => _navController.push('$path/B'),
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
