import 'package:flutter/services.dart';

import 'app_qa_controller.dart';

class AppQaPlatformBridge {
  AppQaPlatformBridge({required this.controller}) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final AppQaController controller;

  static const MethodChannel _channel = MethodChannel('open_pharma_stock/qa');

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'runCommand') {
      return;
    }
    final arguments = Map<String, Object?>.from(call.arguments as Map? ?? {});
    final command = arguments.remove('command') as String?;
    if (command == null || command.isEmpty) {
      return;
    }
    await controller.runCommand(command, arguments);
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}
