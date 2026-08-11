import 'package:flutter/widgets.dart';

import 'app_tour_controller.dart';

class AppTourScope extends InheritedNotifier<AppTourController> {
  const AppTourScope({
    super.key,
    required AppTourController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppTourController of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'AppTourScope not found in context');
    return scope!;
  }

  static AppTourController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTourScope>()?.notifier;
  }
}
