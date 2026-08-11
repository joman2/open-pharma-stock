import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scan_debug_state.dart';
import 'scanner_engine.dart';

class MobileScannerEngine implements ScannerEngine {
  MobileScannerEngine({
    required ScanMode mode,
    this.debugReturnImage = false,
    this.enableFallbackDecoder = false,
    this.debugDpmFrames = false,
    MobileScannerController? controller,
  }) : _mode = mode,
       debug = ValueNotifier(const ScanDebugState()),
       _controller =
           controller ??
           MobileScannerController(
             formats: _supportedFormats,
             autoStart: false,
             detectionSpeed: DetectionSpeed.unrestricted,
             detectionTimeoutMs: 0,
             enableFallbackDecoder: enableFallbackDecoder,
             debugDpmFrames: debugDpmFrames,
             returnImage: debugReturnImage,
           );

  ScanMode _mode;
  final bool debugReturnImage;
  final bool enableFallbackDecoder;
  final bool debugDpmFrames;
  final MobileScannerController _controller;
  final StreamController<ScanResult> _scanController =
      StreamController<ScanResult>.broadcast();
  final ValueNotifier<ScanDebugState> debug;
  String? _lastEmittedRaw;
  DateTime? _lastEmittedAt;
  Future<void>? _transition;
  bool _disposed = false;

  MobileScannerController get controller => _controller;
  ScanMode get mode => _mode;
  Set<BarcodeFormat> get _acceptedFormats => _formatsForMode(_mode).toSet();

  @override
  Stream<ScanResult> get scans => _scanController.stream;

  void handleDetect(BarcodeCapture capture) {
    final now = DateTime.now();
    final debugLines = <String>[];

    if (capture.barcodes.isEmpty) {
      debugLines.add('NO_BARCODES');
    } else {
      for (final barcode in capture.barcodes) {
        final rawValue = barcode.rawValue;
        final formatHint = _formatHint(barcode.format);
        final displayValue = _debugValue(rawValue);
        final isAllowed = _acceptedFormats.contains(barcode.format);
        final inScanWindow = barcode.inScanWindow;

        var line = '$formatHint: $displayValue';
        if (!isAllowed) {
          line += ' REJECTED_BY_MODE';
        } else if (!inScanWindow) {
          line += ' OUTSIDE_ROI';
        }
        debugLines.add(line);

        if (!isAllowed) {
          continue;
        }
        if (!inScanWindow) {
          continue;
        }
        if (rawValue == null || rawValue.isEmpty) {
          continue;
        }
        if (!_shouldEmit(rawValue, now)) {
          continue;
        }
        _scanController.add(ScanResult(raw: rawValue, format: formatHint));
        _logScan(rawValue, formatHint, now);
      }
    }

    _recordDebugLines(debugLines, incrementDetect: true);
  }

  @override
  Future<void> start() async {
    await _runTransition(() async {
      if (_disposed || _controller.value.isRunning) {
        return;
      }
      final stopwatch = Stopwatch()..start();
      _debugLog('[SCANNER] start mode=${_mode.name}');
      await _controller.start();
      stopwatch.stop();
      _debugLog(
        '[SCANNER] started running=${_controller.value.isRunning} '
        'error=${_controller.value.error?.errorCode.name ?? 'none'} '
        'elapsed_ms=${stopwatch.elapsedMilliseconds}',
      );
    });
  }

  @override
  Future<void> stop() async {
    await _runTransition(() async {
      if (_disposed || !_controller.value.isRunning) {
        return;
      }
      _debugLog('[SCANNER] stop mode=${_mode.name}');
      await _controller.stop();
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    await _transition;
    await _controller.dispose();
    await _scanController.close();
    debug.dispose();
  }

  void setMode(ScanMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    _lastEmittedRaw = null;
    _lastEmittedAt = null;
    _debugLog('[SCANNER] mode=${mode.name}');
  }

  Future<void> _runTransition(Future<void> Function() action) async {
    final pending = _transition;
    if (pending != null) {
      await pending;
    }
    if (_disposed) {
      return;
    }
    final completer = Completer<void>();
    _transition = completer.future;
    try {
      await action();
    } finally {
      completer.complete();
      if (identical(_transition, completer.future)) {
        _transition = null;
      }
    }
  }

  void _recordDebugLines(List<String> lines, {required bool incrementDetect}) {
    if (lines.isEmpty) {
      return;
    }
    final current = debug.value;
    final merged = <String>[...current.lastLines, ...lines];
    final trimmed = merged.length > 3
        ? merged.sublist(merged.length - 3)
        : merged;
    debug.value = ScanDebugState(
      detectCount: incrementDetect
          ? current.detectCount + 1
          : current.detectCount,
      lastLines: trimmed,
    );
  }

  static List<BarcodeFormat> _formatsForMode(ScanMode mode) {
    switch (mode) {
      case ScanMode.dataMatrix:
        return [BarcodeFormat.dataMatrix];
      case ScanMode.barcodes:
        return [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.itf,
          BarcodeFormat.codabar,
        ];
    }
  }

  static const List<BarcodeFormat> _supportedFormats = [
    BarcodeFormat.dataMatrix,
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.itf,
    BarcodeFormat.codabar,
  ];

  Duration get _duplicateCooldown => switch (_mode) {
    ScanMode.dataMatrix => const Duration(milliseconds: 1200),
    ScanMode.barcodes => const Duration(milliseconds: 650),
  };

  bool _shouldEmit(String raw, DateTime now) {
    final lastRaw = _lastEmittedRaw;
    final lastAt = _lastEmittedAt;
    if (lastRaw == raw &&
        lastAt != null &&
        now.difference(lastAt) < _duplicateCooldown) {
      return false;
    }
    _lastEmittedRaw = raw;
    _lastEmittedAt = now;
    return true;
  }

  void _logScan(String raw, String format, DateTime now) {
    final trimmed = raw.length > 80 ? raw.substring(0, 80) : raw;
    _debugLog(
      '[SCAN] fmt=$format len=${raw.length} ts=${now.toIso8601String()} raw=$trimmed',
    );
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  String _formatHint(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.dataMatrix:
        return 'DATA_MATRIX';
      case BarcodeFormat.ean13:
        return 'EAN_13';
      case BarcodeFormat.ean8:
        return 'EAN_8';
      case BarcodeFormat.upcA:
        return 'UPC_A';
      case BarcodeFormat.upcE:
        return 'UPC_E';
      case BarcodeFormat.code128:
        return 'CODE_128';
      case BarcodeFormat.code39:
        return 'CODE_39';
      case BarcodeFormat.itf:
        return 'ITF';
      case BarcodeFormat.codabar:
        return 'CODABAR';
      case BarcodeFormat.qrCode:
        return 'QR_CODE';
      default:
        return 'UNKNOWN';
    }
  }

  String _debugValue(String? rawValue) {
    if (rawValue == null) {
      return '<null>';
    }
    if (rawValue.isEmpty) {
      return '<empty>';
    }
    return rawValue;
  }
}
