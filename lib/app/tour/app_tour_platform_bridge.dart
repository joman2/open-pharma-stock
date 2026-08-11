import 'package:flutter/services.dart';

import 'app_tour_controller.dart';

class AppTourPlatformBridge {
  AppTourPlatformBridge({required this.controller}) {
    _channel.setMethodCallHandler(_handleMethodCall);
    controller.addListener(_syncCaptureEnabled);
    _syncCaptureEnabled();
  }

  final AppTourController controller;

  static const MethodChannel _channel = MethodChannel(
    'open_pharma_stock/app_tour',
  );

  Future<void> _handleMethodCall(MethodCall call) async {
    if (!controller.value.isActive) {
      return;
    }

    switch (call.method) {
      case 'next':
        await controller.next();
        return;
      case 'previous':
        await controller.previous();
        return;
      case 'skip':
        await controller.skip();
        return;
      default:
        return;
    }
  }

  Future<void> _syncCaptureEnabled() async {
    await _setCaptureEnabled(controller.value.isActive);
  }

  Future<void> _setCaptureEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setCaptureEnabled', <String, Object?>{
        'enabled': enabled,
      });
    } on MissingPluginException {
      // Only Android automation uses this bridge.
    } catch (_) {
      // Ignore transport failures; the tutorial remains usable without it.
    }
  }

  void dispose() {
    controller.removeListener(_syncCaptureEnabled);
    _setCaptureEnabled(false);
    _channel.setMethodCallHandler(null);
  }
}
