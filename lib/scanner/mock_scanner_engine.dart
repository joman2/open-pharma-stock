import 'dart:async';

import 'scanner_engine.dart';

class MockScannerEngine implements ScannerEngine {
  final StreamController<ScanResult> _controller =
      StreamController<ScanResult>.broadcast();

  @override
  Stream<ScanResult> get scans => _controller.stream;

  void addScan(String raw, {String? format}) {
    _controller.add(ScanResult(raw: raw, format: format));
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  Future<void> dispose() async {
    await _controller.close();
  }
}
