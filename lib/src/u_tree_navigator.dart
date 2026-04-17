import 'dart:io';

import 'package:flutter/widgets.dart';

class UNavCntlr extends ChangeNotifier {
  final navKey = GlobalKey<NavigatorState>();
  NavigatorState? get _navigator => navKey.currentState;
  final _forwardPaths = <String>[];
  String curPath = '/';
  late final _treeNavObserver = _UTreeNavObserver(onPopped: _onPopped);

  void _onPopped(String poppedPath, String previousPath) {
    notifyListeners();
    curPath = previousPath;
    _forwardPaths.add(poppedPath);
  }

  void push(String path, {bool isForward = false}) {
    _navigator?.pushNamed(path);
    notifyListeners();
    curPath = path;
    isForward ? _forwardPaths.removeLast() : _forwardPaths.clear();
  }

  bool canPop() => _navigator?.canPop() == true;

  bool canForward() => _forwardPaths.isNotEmpty;

  void tryForward() {
    if (!canForward()) return;
    final forwardPath = _forwardPaths.last;
    push(forwardPath, isForward: true);
  }

  void tryPop() => _navigator?.maybePop();

  bool canUp() {
    return curPath.startsWith(Platform.pathSeparator);
  }

  void tryUp() {
    if (!canUp()) return;
    final endIndex = curPath.lastIndexOf(Platform.pathSeparator);
    if (endIndex < 0) return;
    final upPath = curPath.substring(0, endIndex);
    push(upPath);
  }
}

class _UTreeNavObserver extends NavigatorObserver {
  final void Function(String path, String previousPath) onPopped;

  _UTreeNavObserver({required this.onPopped});

  @override
  void didPop(Route route, Route? previousRoute) {
    final poppedPath = route.settings.name;
    final previousPath = previousRoute?.settings.name;
    if (poppedPath == null || previousPath == null) return;
    onPopped(poppedPath, previousPath);
  }
}

class UTreeNavigator extends StatefulWidget {
  const UTreeNavigator({
    super.key,
    required this.cntlr,
    required this.widgetBuilder,
    this.initialPath = '/',
    required this.onPopRoot,
  });

  final VoidCallback onPopRoot;
  final UNavCntlr cntlr;
  final Widget Function(String? path) widgetBuilder;
  final String initialPath;

  @override
  State<UTreeNavigator> createState() => _UTreeNavigatorState();
}

class _UTreeNavigatorState extends State<UTreeNavigator> {
  UNavCntlr get _cntlr => widget.cntlr;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_cntlr.canPop()) {
          _cntlr.tryPop();
        } else {
          widget.onPopRoot();
        }
      },
      child: Navigator(
        observers: [_cntlr._treeNavObserver],
        key: _cntlr.navKey,
        initialRoute: widget.initialPath,
        onGenerateRoute: (settings) {
          var path = settings.name ?? '';
          _cntlr.curPath = path;
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (_, __, ___) => widget.widgetBuilder(path),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          );
        },
      ),
    );
  }
}
