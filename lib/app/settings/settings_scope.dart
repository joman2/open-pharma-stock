import 'package:flutter/widgets.dart';

import 'app_settings.dart';

class SettingsScope extends InheritedNotifier<AppSettingsController> {
  const SettingsScope({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope not found in context');
    return scope!.notifier!;
  }
}
