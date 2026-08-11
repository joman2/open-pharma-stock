enum ScanMode { dataMatrix, barcodes }

class ScanResult {
  const ScanResult({required this.raw, this.format});

  final String raw;
  final String? format;
}

abstract class ScannerEngine {
  Stream<ScanResult> get scans;
  Future<void> start();
  Future<void> stop();
}
