import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';
import 'u_split_panel.dart';

class USplitLayout extends StatefulWidget {
  const USplitLayout({
    super.key,
    required this.panels,
    required this.direction,
    this.dividerBuilder,
  }) : assert(panels.length > 1);

  final List<USplitPanel> panels;
  final Axis direction;
  final Widget Function(int index)? dividerBuilder;

  @override
  State<USplitLayout> createState() => _USplitLayoutState();
}

class _USplitLayoutState extends State<USplitLayout> {
  final List<ValueNotifier<double>> _sizeNotifiers = [];
  late double _mainAxisExtent;

  void _onDragDivider(int dividerIndex, Offset delta) {
    final deltaFlex = widget.direction == Axis.horizontal
        ? delta.dx / _mainAxisExtent
        : delta.dy / _mainAxisExtent;
    final currentFlex = _sizeNotifiers[dividerIndex].value;
    final nextFlex = _sizeNotifiers[dividerIndex + 1].value;
    final totalFlex = currentFlex + nextFlex;
    final newCurrentFlex = (currentFlex - deltaFlex * totalFlex).clamp(
      0.1,
      totalFlex - 0.1,
    );
    _sizeNotifiers[dividerIndex].value = newCurrentFlex;
    _sizeNotifiers[dividerIndex + 1].value = totalFlex - newCurrentFlex;
  }

  @override
  void initState() {
    super.initState();
    for (final panel in widget.panels) {
      _sizeNotifiers.add(ValueNotifier(panel.flex.toDouble()));
    }
  }

  Widget _buildDivider(int index) {
    return GestureDetector(
      onPanUpdate: (details) => _onDragDivider(index, details.delta),
      child: MouseRegion(
        cursor: widget.direction == Axis.horizontal
            ? SystemMouseCursors.resizeColumn
            : SystemMouseCursors.resizeRow,
        child:
            widget.dividerBuilder?.call(index) ??
            const SizedBox(width: 1, height: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _mainAxisExtent = widget.direction == Axis.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        return Flex(
          direction: widget.direction,
          children: [
            for (int i = 0; i < widget.panels.length - 1; i++) ...[
              _SplitChild(
                sizeNotifier: _sizeNotifiers[i],
                direction: widget.direction,
                child: widget.panels[i].child,
              ),
              Container(
                width: widget.direction == Axis.vertical ? null : 1,
                height: widget.direction == Axis.horizontal ? null : 1,
                color: theme.secondary.withAlpha(77),
              ),
            ],
            _SplitChild(
              sizeNotifier: _sizeNotifiers.last,
              direction: widget.direction,
              child: widget.panels.last.child,
            ),
          ],
        );
      },
    );
  }
}

class _SplitChild extends StatelessWidget {
  const _SplitChild({
    required this.sizeNotifier,
    required this.direction,
    required this.child,
  });

  final ValueNotifier<double> sizeNotifier;
  final Axis direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: sizeNotifier,
      builder: (context, size, panel) {
        return SizedBox(
          width: direction == Axis.horizontal ? size * 100 : null,
          height: direction == Axis.vertical ? size * 100 : null,
          child: panel,
        );
      },
      child: child,
    );
  }
}
