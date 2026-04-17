import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'package:u_widget/u_widget.dart';

class TabBarExample extends StatefulWidget {
  const TabBarExample({super.key});

  @override
  State<TabBarExample> createState() => _TabBarExampleState();
}

class _TabBarExampleState extends State<TabBarExample> {
  int _tabCount = 3;
  late final _cntlr = UTabCntlr(
    initialTabs: List.generate(
      _tabCount,
      (index) => UTab(uniqueKey: UniqueKey(), name: '页面$index'),
    ),
    initialIndex: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标签栏组件 (UTabBar)'),
        actions: [
          UButton(
            padding: EdgeInsets.all(6),
            child: const Icon(Icons.add, size: 16),
            onPressed: () {
              _cntlr.addTab(UTab(uniqueKey: UniqueKey(), name: '页面$_tabCount'));
              _tabCount++;
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: UTheme.of(context).paddingLarge,
        children: [
          SizedBox(
            height: 40,
            child: UTabBar(
              cntlr: _cntlr,
              tabBuilder: _buildTab,
              // suffix: UButton(
              //   padding: EdgeInsets.zero,
              //   child: const Icon(Icons.add, size: 16),
              //   onPressed: () {
              //     _cntlr.addTab(UTab(uniqueKey: UniqueKey(), name: '新标签'));
              //   },
              // ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index) {
    final theme = UTheme.of(context);
    final tab = _cntlr.getTab(index);
    final isCloseable = tab.closeable;
    return ListenableBuilder(
      listenable: _cntlr,
      builder: (context, child) {
        final selected = _cntlr.selected(index);
        return UButton(
          onTertiaryTapUp: (_) => _cntlr.removeTab(index),
          radius: 6,
          padding: theme.paddingSmall,
          backgroundColor: selected ? null : theme.background,
          child: Row(
            children: [
              const SizedBox(width: 24),
              Text(tab.name),
              if (isCloseable) ...[
                const SizedBox(width: 18),
                UButton(
                  contentColor: selected ? Colors.white : Colors.black,
                  backgroundColor: Colors.transparent,
                  borderColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  child: const Icon(Icons.close, size: 16),
                  onPressed: () => _cntlr.removeTab(index),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
