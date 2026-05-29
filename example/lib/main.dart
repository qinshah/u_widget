import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'components/button/button_example.dart';
import 'components/video_player/video_player_example.dart';
import 'components/input/input_example.dart';
import 'components/scroll_picker/scroll_picker_example.dart';
import 'components/file_list/file_list_example.dart';
import 'components/navigation_bar/navigation_bar_example.dart';
import 'components/tree_view/tree_view_example.dart';
import 'components/split_layout/split_layout_example.dart';
import 'components/tree_navigator/tree_navigator_example.dart';
import 'components/tab_bar/tab_bar_example.dart';
import 'components/window/window_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UWidget Demo',
      theme: UThemeData.defaultTheme().toMaterial(),
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
            '标签栏组件 (UTabBar)',
            '支持多个标签页',
            () => const TabBarExample(),
          ),
          _buildSection(
            context,
            '视频播放器 (UVideoPlayer)',
            '集成全屏切换和UI交互回调',
            () => const VideoPlayerExample(),
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
          _buildSection(
            context,
            '窗口组件 (UWindow/UWindows)',
            '支持拖拽、调整尺寸、最大化和Z轴顺序管理',
            () => const WindowExamplePage(),
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
          padding: EdgeInsets.only(top: theme.spacingSmall),
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
