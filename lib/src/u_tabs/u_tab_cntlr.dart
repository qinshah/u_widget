import 'package:flutter/foundation.dart';
import 'package:u_widget/u_widget.dart';

class UTabCntlr extends ChangeNotifier {
  UTabCntlr({List<UTab> initialTabs = const [], int initialIndex = 0})
    : _tabs = List.from(initialTabs),
      _index = initialIndex > -1 && initialIndex < initialTabs.length
          ? initialIndex
          : 0;

  bool _indexIsValid(int index) => index > -1 && index < _tabs.length;

  final List<UTab> _tabs;
  int _index;

  bool selected(int index) => _index == index;

  int get tabCount => _tabs.length;

  void addTab(UTab tab, [bool autoActivate = true]) {
    _tabs.add(tab);
    if (autoActivate) _index = _tabs.length - 1;
    notifyListeners();
  }

  void removeTab(int index) {
    if (_tabs.isEmpty) return;
    _tabs.removeAt(index);
    if (_index >= _tabs.length && _tabs.isNotEmpty) {
      _index = _tabs.length - 1;
    } else if (_index > index && _index > 0) {
      _index--;
    }
    if (_tabs.isEmpty) {
      _index = 0;
    }
    notifyListeners();
  }

  void setActiveIndex(int index) {
    if (index >= 0 && index < _tabs.length) {
      _index = index;
      notifyListeners();
    }
  }

  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = _tabs.removeAt(oldIndex);
    _tabs.insert(newIndex, item);

    if (_index == oldIndex) {
      _index = newIndex;
    } else if (oldIndex < _index && newIndex >= _index) {
      _index--;
    } else if (oldIndex > _index && newIndex <= _index) {
      _index++;
    }

    notifyListeners();
  }

  UTab getTab(int index) {
    if (!_indexIsValid(index)) throw 'Invalid index: $index';
    return _tabs[index];
  }
}
