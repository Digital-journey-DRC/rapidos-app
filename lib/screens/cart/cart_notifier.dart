import 'package:flutter/material.dart';
import 'dart:async';

class CartNotifier extends InheritedWidget {
  StreamController<void>? streamController;

  CartNotifier({
    Key? key,
    required Widget child,
    this.streamController,
  }) : super(key: key, child: child);

  static CartNotifier of(BuildContext context) {
    final CartNotifier? result = context.dependOnInheritedWidgetOfExactType<CartNotifier>();
    assert(result != null, 'No CartNotifier found in context');
    return result!;
  }

  void notifyCartChanged() {
    streamController?.add(null);
  }

  @override
  bool updateShouldNotify(CartNotifier oldWidget) {
    return streamController != oldWidget.streamController;
  }
} 