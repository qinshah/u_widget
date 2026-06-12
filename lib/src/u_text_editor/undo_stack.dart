part of '../u_text_editor.dart';

// ===================== Undo Stack =====================

class _UndoStack<T> {
  final List<T> _list = <T>[];
  int _index = -1;

  T? get currentValue =>
      _list.isEmpty ? null : (_index >= 0 && _index < _list.length ? _list[_index] : null);

  void push(T value) {
    if (_list.isEmpty) {
      _list.add(value);
      _index = 0;
      return;
    }

    assert(_index < _list.length && _index >= 0);

    if (value == currentValue) {
      return;
    }

    if (_index != _list.length - 1) {
      _list.removeRange(_index + 1, _list.length);
    }
    _list.add(value);
    _index = _list.length - 1;
  }

  T? undo() {
    if (_list.isEmpty) return null;
    assert(_index < _list.length && _index >= 0);
    if (_index != 0) {
      _index = _index - 1;
    }
    return currentValue;
  }

  T? redo() {
    if (_list.isEmpty) return null;
    assert(_index < _list.length && _index >= 0);
    if (_index < _list.length - 1) {
      _index = _index + 1;
    }
    return currentValue;
  }

  void clear() {
    _list.clear();
    _index = -1;
  }
}