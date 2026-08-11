import 'package:flutter/services.dart';

class AppBackupPlatformBridge {
  static const MethodChannel _channel = MethodChannel('open_pharma_stock/backup');

  Future<String?> writeBackupToDownloads({
    required String fileName,
    required String content,
  }) {
    return _channel.invokeMethod<String>('writeBackupToDownloads', {
      'fileName': fileName,
      'content': content,
    });
  }
}
