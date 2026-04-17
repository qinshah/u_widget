import 'dart:async';

import 'package:flutter/material.dart';
import 'package:u_widget/u_widget.dart';

class UTabBar extends StatefulWidget {
  final UTabCntlr cntlr;

  /// Callback when tabs are reordered
  final void Function(int oldIndex, int newIndex)? onTabsReordered;

  /// Defaults to [Axis.horizontal].
  ///
  /// See also: [Axis]
  final Axis direction;

  final IndexedWidgetBuilder tabBuilder;

  // final Widget? suffix;

  const UTabBar({
    super.key,
    required this.cntlr,
    this.onTabsReordered,
    this.direction = Axis.horizontal,
    required this.tabBuilder,
    // this.suffix,
  });

  @override
  State<UTabBar> createState() => _UTabBarState();
}

class _UTabBarState extends State<UTabBar> {
  Timer _mouseTimer = Timer(Duration.zero, () {})..cancel();

  @override
  void dispose() {
    _mouseTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: (_) {
        final wasInactive = !_mouseTimer.isActive;
        _mouseTimer.cancel();
        _mouseTimer = Timer(Duration(milliseconds: 500), () {
          setState(_mouseTimer.cancel);
        });
        if (wasInactive) setState(() {}); // isActive = true;
      },
      child: ListenableBuilder(
        listenable: widget.cntlr,
        builder: (context, child) {
          return ReorderableListView.builder(
            itemCount: widget.cntlr.tabCount,
            // itemCount: widget.cntlr.tabCount + (widget.suffix != null ? 1 : 0),
            scrollDirection: widget.direction,
            onReorder: _onReorder,
            onReorderStart: widget.cntlr.setActiveIndex,
            itemBuilder: (context, index) {
              // if (index == widget.cntlr.tabCount) {
              //   return Center(key: UniqueKey(), child: widget.suffix);
              // }
              final tab = widget.cntlr.getTab(index);
              // 根据是否为鼠标判断是否需要长按拖拽
              if (_mouseTimer.isActive) {
                return ReorderableDragStartListener(
                  key: tab.uniqueKey,
                  index: index,
                  child: widget.tabBuilder(context, index),
                );
              }
              return ReorderableDelayedDragStartListener(
                key: tab.uniqueKey,
                index: index,
                child: widget.tabBuilder(context, index),
              );
            },
            // 拖拽时的tab样式
            proxyDecorator: (child, index, animation) {
              return Material(color: Colors.transparent, child: child);
            },
            buildDefaultDragHandles: false, // 不显示默认的拖拽句柄
          );
        },
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    widget.cntlr.reorderTabs(oldIndex, newIndex);
    widget.onTabsReordered?.call(oldIndex, newIndex);
  }
}
