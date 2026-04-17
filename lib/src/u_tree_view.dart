import 'package:flutter/material.dart';
import 'package:u_design/u_design.dart';

class UTreeView<T extends Object> extends StatefulWidget {
  const UTreeView({
    super.key,
    required this.rootNode,
    this.onNodeTap,
    this.itemBuilder,
    this.expanderIconBuilder,
  });

  final UTreeNode<T> rootNode;
  final Function(UTreeNode<T>)? onNodeTap;
  final Widget Function(BuildContext, UTreeNode<T>)? itemBuilder;
  final Widget Function(BuildContext, UTreeNode<T>, bool)? expanderIconBuilder;

  @override
  State<UTreeView<T>> createState() => _UTreeViewState<T>();
}

class _UTreeViewState<T extends Object> extends State<UTreeView<T>> {
  final Set<UProgressNodePath> _expandedNodes = {};

  @override
  Widget build(BuildContext context) {
    final theme = UTheme.of(context);
    return Theme(
      data: theme.toMaterial(),
      child: ListView(children: _buildNodeTree(widget.rootNode, 0)),
    );
  }

  List<Widget> _buildNodeTree(UTreeNode<T> node, int depth) {
    List<Widget> widgets = [];
    for (final child in node.children) {
      widgets.add(_buildNode(child, depth));
    }
    return widgets;
  }

  Widget _buildNode(UTreeNode<T> node, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => widget.onNodeTap?.call(node),
          child: Padding(
            padding: EdgeInsets.only(left: depth * 16.0),
            child: Row(
              children: [
                if (node.children.isNotEmpty)
                  GestureDetector(
                    onTap: () => _toggleNode(node),
                    child: Icon(
                      _expandedNodes.contains(node.path)
                          ? Icons.expand_more
                          : Icons.chevron_right,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child:
                      widget.itemBuilder?.call(context, node) ??
                      Text(node.data.toString()),
                ),
              ],
            ),
          ),
        ),
        if (_expandedNodes.contains(node.path))
          ..._buildNodeTree(node, depth + 1),
      ],
    );
  }

  void _toggleNode(UTreeNode<T> node) {
    setState(() {
      if (_expandedNodes.contains(node.path)) {
        _expandedNodes.remove(node.path);
      } else {
        _expandedNodes.add(node.path);
      }
    });
  }
}

class UTreeNode<T> {
  final T data;
  final List<UTreeNode<T>> children;
  final UTreeNode<T>? parent;
  late final UProgressNodePath path;

  UTreeNode({required this.data, this.children = const [], this.parent}) {
    path = UProgressNodePath.fromNode(this);
  }
}

class UProgressNodePath implements Comparable<UProgressNodePath> {
  final List<int> segments;

  UProgressNodePath(this.segments);

  factory UProgressNodePath.fromNode(UTreeNode node) {
    final segments = <int>[];
    var current = node;
    while (current.parent != null) {
      final index = current.parent!.children.indexOf(current);
      if (index >= 0) segments.insert(0, index);
      current = current.parent!;
    }
    return UProgressNodePath(segments);
  }

  @override
  int compareTo(UProgressNodePath other) {
    final minLength = segments.length < other.segments.length
        ? segments.length
        : other.segments.length;
    for (int i = 0; i < minLength; i++) {
      if (segments[i] != other.segments[i]) {
        return segments[i].compareTo(other.segments[i]);
      }
    }
    return segments.length.compareTo(other.segments.length);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UProgressNodePath && _listEquals(segments, other.segments);

  @override
  int get hashCode => segments.hashCode;

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
