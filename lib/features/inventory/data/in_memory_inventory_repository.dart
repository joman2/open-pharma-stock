import '../../../core/gs1/gs1_parser.dart';
import '../../../core/gs1/scan_normalizer.dart';
import '../domain/inventory_repository.dart';
import '../domain/models.dart';

class InMemoryInventoryRepository implements InventoryRepository {
  final List<InventorySession> _sessions = [];
  final List<ScanEvent> _events = [];
  int _nextId = 1;

  String _newId() => (_nextId++).toString();

  InventorySession _touchSession(InventorySession session) {
    final updated = InventorySession(
      id: session.id,
      name: session.name,
      createdAt: session.createdAt,
      updatedAt: DateTime.now(),
      barcodeQuantityPromptEnabled: session.barcodeQuantityPromptEnabled,
    );
    final index = _sessions.indexWhere((item) => item.id == session.id);
    if (index != -1) {
      _sessions[index] = updated;
    }
    return updated;
  }

  @override
  Future<InventorySession> createSession(
    String name, {
    bool barcodeQuantityPromptEnabled = false,
  }) async {
    final now = DateTime.now();
    final session = InventorySession(
      id: _newId(),
      name: name,
      createdAt: now,
      updatedAt: now,
      barcodeQuantityPromptEnabled: barcodeQuantityPromptEnabled,
    );
    _sessions.add(session);
    return session;
  }

  @override
  Future<List<InventorySession>> listSessions() async {
    final sessions = List<InventorySession>.from(_sessions);
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  @override
  Future<InventorySession?> getSession(String sessionId) async {
    for (final session in _sessions) {
      if (session.id == sessionId) {
        return session;
      }
    }
    return null;
  }

  @override
  Future<InventorySession> updateSessionBarcodeQuantityPrompt(
    String sessionId,
    bool enabled,
  ) async {
    final index = _sessions.indexWhere((session) => session.id == sessionId);
    if (index == -1) {
      throw StateError('Sessão não encontrada: $sessionId');
    }
    final current = _sessions[index];
    final updated = InventorySession(
      id: current.id,
      name: current.name,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      barcodeQuantityPromptEnabled: enabled,
    );
    _sessions[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((session) => session.id == sessionId);
    _events.removeWhere((event) => event.sessionId == sessionId);
  }

  @override
  Future<RegisterScanResult> registerScan({
    required String sessionId,
    required String raw,
    String? formatHint,
  }) async {
    final parser = Gs1Parser();
    final parsed = parser.parse(raw);
    final now = DateTime.now();
    final gtinForDedupe = parsed.gtin;
    final serialNumber = gtinForDedupe != null ? parsed.serialNumber : null;
    final lot = gtinForDedupe != null ? parsed.lot : null;
    final expiry = gtinForDedupe != null ? parsed.expiry : null;
    if (gtinForDedupe != null && serialNumber != null) {
      final exists = _events.any(
        (event) =>
            event.sessionId == sessionId &&
            event.productCode == gtinForDedupe &&
            event.serialNumber == serialNumber &&
            !event.isDeleted,
      );
      if (exists) {
        return const RegisterScanResult(event: null, wasDuplicateSerial: true);
      }
    }

    final normalized = normalizeScan(raw, formatHint: formatHint);
    final productCode = gtinForDedupe ?? normalized.productCode;
    final codeType = gtinForDedupe != null
        ? CodeType.gtin
        : normalized.codeType;
    final event = ScanEvent(
      id: _newId(),
      sessionId: sessionId,
      productCode: productCode,
      codeType: codeType,
      raw: raw,
      serialNumber: serialNumber,
      lot: lot,
      expiry: expiry,
      createdAt: now,
      isDeleted: false,
    );
    _events.add(event);
    final session = await getSession(sessionId);
    if (session != null) {
      _touchSession(session);
    }
    return RegisterScanResult(event: event, wasDuplicateSerial: false);
  }

  @override
  Future<List<InventoryItem>> listItems(String sessionId) async {
    final active = _events.where(
      (event) => event.sessionId == sessionId && !event.isDeleted,
    );
    final Map<String, List<ScanEvent>> grouped = {};
    for (final event in active) {
      final key = '${event.productCode}|${event.codeType}';
      grouped.putIfAbsent(key, () => []).add(event);
    }
    final items = grouped.entries.map((entry) {
      final events = entry.value;
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latest = events.first;
      return InventoryItem(
        id: entry.key,
        sessionId: sessionId,
        productCode: latest.productCode,
        codeType: latest.codeType,
        qty: events.length,
        lastScanAt: latest.createdAt,
      );
    }).toList();
    items.sort((a, b) => b.lastScanAt.compareTo(a.lastScanAt));
    return items;
  }

  @override
  Future<List<ScanEvent>> listEventsForSession(String sessionId) async {
    final events = _events
        .where((event) => event.sessionId == sessionId)
        .toList();
    events.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return events;
  }

  @override
  Future<List<ScanEvent>> listRecentEvents(
    String sessionId, {
    int limit = 50,
  }) async {
    final events = _events
        .where((event) => event.sessionId == sessionId)
        .toList();
    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (events.length > limit) {
      return events.take(limit).toList();
    }
    return events;
  }

  @override
  Future<List<ScanEvent>> listEventsForProduct(
    String sessionId,
    String productCode,
  ) async {
    final events = _events
        .where(
          (event) =>
              event.sessionId == sessionId && event.productCode == productCode,
        )
        .toList();
    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return events;
  }

  @override
  Future<bool> deleteEvent(String eventId) async {
    final index = _events.indexWhere((event) => event.id == eventId);
    if (index == -1) {
      return false;
    }
    final current = _events[index];
    if (current.isDeleted) {
      return false;
    }
    _events[index] = ScanEvent(
      id: current.id,
      sessionId: current.sessionId,
      productCode: current.productCode,
      codeType: current.codeType,
      raw: current.raw,
      serialNumber: current.serialNumber,
      lot: current.lot,
      expiry: current.expiry,
      createdAt: current.createdAt,
      isDeleted: true,
    );
    final session = await getSession(current.sessionId);
    if (session != null) {
      _touchSession(session);
    }
    return true;
  }

  @override
  Future<int> deleteRecentEvents(
    String sessionId,
    String productCode, {
    int count = 1,
  }) async {
    if (count <= 0) {
      return 0;
    }
    final events = _events
        .where(
          (event) =>
              event.sessionId == sessionId &&
              event.productCode == productCode &&
              !event.isDeleted,
        )
        .toList();
    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final toDelete = events.take(count).toList();
    for (final event in toDelete) {
      await deleteEvent(event.id);
    }
    return toDelete.length;
  }

  @override
  Future<int> deleteAllEventsForProduct(
    String sessionId,
    String productCode,
  ) async {
    final events = _events
        .where(
          (event) =>
              event.sessionId == sessionId &&
              event.productCode == productCode &&
              !event.isDeleted,
        )
        .toList();
    for (final event in events) {
      await deleteEvent(event.id);
    }
    return events.length;
  }
}
