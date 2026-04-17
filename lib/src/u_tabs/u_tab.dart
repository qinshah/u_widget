import 'package:flutter/foundation.dart';

class UTab {
  final UniqueKey uniqueKey;
  final String name;
  final bool closeable;

  UTab({required this.uniqueKey, required this.name, this.closeable = true});
}