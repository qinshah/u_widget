import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';

class UScrollPickerItem<T> {
  final T value;
  final List<UScrollPickerItem<T>> children;

  UScrollPickerItem({required this.value, this.children = const []});
}

class UScrollPicker<T> extends StatefulWidget {
  const UScrollPicker({
    super.key,
    this.itemExtent = 40,
    this.columns = 1,
    required this.items,
    required this.onChanged,
  });

  final ValueChanged<List<T?>> onChanged;
  final double itemExtent;
  final List<UScrollPickerItem<T>> items;
  final int columns;

  @override
  State<UScrollPicker<T>> createState() => _UScrollPickerState<T>();
}

class _UScrollPickerState<T> extends State<UScrollPicker<T>> {
  late final List<UScrollPickerItem<T>?> _selectedItems = List.filled(
    widget.columns,
    null,
  );
  late final List<FixedExtentScrollController> _controllers = List.generate(
    widget.columns,
    (_) => FixedExtentScrollController(),
  );

  @override
  void initState() {
    super.initState();
    _initSelectedItems();
  }

  void _initSelectedItems() {
    if (widget.items.isEmpty) return;
    _selectedItems[0] = widget.items.first;
    for (int i = 1; i < widget.columns; i++) {
      final children = _selectedItems[i - 1]?.children ?? [];
      _selectedItems[i] = children.isNotEmpty ? children.first : null;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onColumnChanged(
    int columnIndex,
    int itemIndex,
    List<UScrollPickerItem<T>> items,
  ) {
    setState(() {
      _selectedItems[columnIndex] = items[itemIndex];
      for (int i = columnIndex + 1; i < widget.columns; i++) {
        final children = _selectedItems[i - 1]?.children ?? [];
        if (children.isEmpty) {
          _selectedItems[i] = null;
          continue;
        }
        final currentIndex = _controllers[i].hasClients
            ? _controllers[i].selectedItem
            : 0;
        final clampedIndex = currentIndex.clamp(0, children.length - 1);
        _selectedItems[i] = children[clampedIndex];
      }
    });
    widget.onChanged(_selectedItems.map((item) => item?.value).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Row(
      children: [
        _buildColumn(widget.items, 0, theme),
        for (int i = 1; i < widget.columns; i++) ...[
          SizedBox(width: theme.spacingSmall),
          _buildColumn(_selectedItems[i - 1]?.children ?? [], i, theme),
        ],
      ],
    );
  }

  Widget _buildColumn(
    List<UScrollPickerItem<T>> items,
    int columnIndex,
    UThemeData theme,
  ) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListWheelScrollView.useDelegate(
            controller: _controllers[columnIndex],
            itemExtent: widget.itemExtent,
            onSelectedItemChanged: (index) {
              _onColumnChanged(columnIndex, index, items);
            },
            physics: const FixedExtentScrollPhysics(),
            overAndUnderCenterOpacity: 0.2,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (BuildContext context, int index) {
                return Container(
                  alignment: Alignment.center,
                  child: Text(items[index].value.toString()),
                );
              },
            ),
            useMagnifier: true,
          ),
          IgnorePointer(
            child: Container(
              height: widget.itemExtent,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: theme.secondary.withAlpha(77)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
