import 'models.dart';

abstract class InventoryRepository {
  Future<InventorySession> createSession(
    String name, {
    bool barcodeQuantityPromptEnabled = false,
  });
  Future<List<InventorySession>> listSessions();
  Future<InventorySession?> getSession(String sessionId);
  Future<InventorySession> updateSessionBarcodeQuantityPrompt(
    String sessionId,
    bool enabled,
  );
  Future<void> deleteSession(String sessionId);

  Future<RegisterScanResult> registerScan({
    required String sessionId,
    required String raw,
    String? formatHint,
  });
  Future<List<InventoryItem>> listItems(String sessionId);
  Future<List<ScanEvent>> listEventsForSession(String sessionId);
  Future<List<ScanEvent>> listRecentEvents(String sessionId, {int limit = 50});
  Future<List<ScanEvent>> listEventsForProduct(
    String sessionId,
    String productCode,
  );
  Future<bool> deleteEvent(String eventId);
  Future<int> deleteRecentEvents(
    String sessionId,
    String productCode, {
    int count = 1,
  });
  Future<int> deleteAllEventsForProduct(String sessionId, String productCode);
}
