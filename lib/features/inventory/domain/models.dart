class InventorySession {
  const InventorySession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.barcodeQuantityPromptEnabled,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool barcodeQuantityPromptEnabled;
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.sessionId,
    required this.productCode,
    required this.codeType,
    required this.qty,
    required this.lastScanAt,
  });

  final String id;
  final String sessionId;
  final String productCode;
  final String codeType;
  final int qty;
  final DateTime lastScanAt;
}

class ScanEvent {
  const ScanEvent({
    required this.id,
    required this.sessionId,
    required this.productCode,
    required this.codeType,
    required this.raw,
    required this.serialNumber,
    required this.lot,
    required this.expiry,
    required this.createdAt,
    required this.isDeleted,
  });

  final String id;
  final String sessionId;
  final String productCode;
  final String codeType;
  final String raw;
  final String? serialNumber;
  final String? lot;
  final DateTime? expiry;
  final DateTime createdAt;
  final bool isDeleted;
}

class RegisterScanResult {
  const RegisterScanResult({
    required this.event,
    required this.wasDuplicateSerial,
  });

  final ScanEvent? event;
  final bool wasDuplicateSerial;
}
