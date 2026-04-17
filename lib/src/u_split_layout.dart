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

  @override
  void initState() {
    super.initState();
    for (final panel in widget.panels) {
      _sizeNotifiers.add(ValueNotifier(panel.flex.toDouble()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
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
