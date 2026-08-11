import 'package:flutter/widgets.dart';

import 'app_qa_controller.dart';

class AppQaScope extends InheritedWidget {
  const AppQaScope({super.key, required this.controller, required super.child});

  final AppQaController controller;

  static AppQaController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppQaScope>()?.controller;
  }

  @override
  bool updateShouldNotify(covariant AppQaScope oldWidget) {
    return oldWidget.controller != controller;
  }
}
