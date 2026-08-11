import 'package:drift/drift.dart';

import '../../../core/gs1/gs1_parser.dart';
import '../../../core/gs1/scan_normalizer.dart';
import '../domain/inventory_repository.dart';
import '../domain/models.dart';
import 'app_database.dart';

class DriftInventoryRepository implements InventoryRepository {
  DriftInventoryRepository({required this.db, Gs1Parser? gs1Parser})
    : _parser = gs1Parser ?? Gs1Parser();

  final AppDatabase db;
  final Gs1Parser _parser;
  int _counter = 0;

  String _newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _counter += 1;
    return '$now-$_counter';
  }

  Future<void> _touchSession(String sessionId, DateTime timestamp) async {
    await (db.update(db.inventorySessions)
          ..where((t) => t.id.equals(sessionId)))
        .write(InventorySessionsCompanion(updatedAt: Value(timestamp)));
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
    await db
        .into(db.inventorySessions)
        .insert(
          InventorySessionsCompanion.insert(
            id: session.id,
            name: session.name,
            createdAt: session.createdAt,
            updatedAt: session.updatedAt,
            barcodeQuantityPromptEnabled: Value(
              session.barcodeQuantityPromptEnabled,
            ),
          ),
        );
    return session;
  }

  @override
  Future<List<InventorySession>> listSessions() async {
    final rows =
        await (db.select(db.inventorySessions)..orderBy([
              (t) => OrderingTerm(
                expression: t.updatedAt,
                mode: OrderingMode.desc,
              ),
            ]))
            .get();
    return rows
        .map(
          (row) => InventorySession(
            id: row.id,
            name: row.name,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            barcodeQuantityPromptEnabled: row.barcodeQuantityPromptEnabled,
          ),
        )
        .toList();
  }

  @override
  Future<InventorySession?> getSession(String sessionId) async {
    final row = await (db.select(
      db.inventorySessions,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return InventorySession(
      id: row.id,
      name: row.name,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      barcodeQuantityPromptEnabled: row.barcodeQuantityPromptEnabled,
    );
  }

  @override
  Future<InventorySession> updateSessionBarcodeQuantityPrompt(
    String sessionId,
    bool enabled,
  ) async {
    final now = DateTime.now();
    await (db.update(db.inventorySessions)..where((t) => t.id.equals(sessionId)))
        .write(
          InventorySessionsCompanion(
            updatedAt: Value(now),
            barcodeQuantityPromptEnabled: Value(enabled),
          ),
        );
    final updated = await getSession(sessionId);
    if (updated == null) {
      throw StateError('Sessão não encontrada: $sessionId');
    }
    return updated;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await db.transaction(() async {
      await (db.delete(
        db.scanEvents,
      )..where((t) => t.sessionId.equals(sessionId))).go();
      await (db.delete(
        db.inventorySessions,
      )..where((t) => t.id.equals(sessionId))).go();
    });
  }

  @override
  Future<RegisterScanResult> registerScan({
    required String sessionId,
    required String raw,
    String? formatHint,
  }) async {
    return db.transaction(() async {
      final parsed = _parser.parse(raw);
      final now = DateTime.now();

      final gtinForDedupe = parsed.gtin;
      final serialNumber = gtinForDedupe != null ? parsed.serialNumber : null;
      final lot = gtinForDedupe != null ? parsed.lot : null;
      final expiryIso = _expiryToIsoDate(
        gtinForDedupe != null ? parsed.expiry : null,
      );
      if (gtinForDedupe != null && serialNumber != null) {
        final existing =
            await (db.select(db.scanEvents)..where(
                  (t) =>
                      t.sessionId.equals(sessionId) &
                      t.productCode.equals(gtinForDedupe) &
                      t.serialNumber.equals(serialNumber) &
                      t.isDeleted.equals(false),
                ))
                .getSingleOrNull();
        if (existing != null) {
          return const RegisterScanResult(
            event: null,
            wasDuplicateSerial: true,
          );
        }
      }

      final normalized = normalizeScan(raw, formatHint: formatHint);
      final productCode = gtinForDedupe ?? normalized.productCode;
      final codeType = gtinForDedupe != null
          ? CodeType.gtin
          : normalized.codeType;
      final eventId = _newId();
      await db
          .into(db.scanEvents)
          .insert(
            ScanEventsCompanion.insert(
              id: eventId,
              sessionId: sessionId,
              productCode: productCode,
              codeType: codeType,
              raw: raw,
              serialNumber: Value(serialNumber),
              lot: Value(lot),
              expiry: Value(expiryIso),
              createdAt: now,
              isDeleted: const Value(false),
            ),
          );

      await _touchSession(sessionId, now);

      return RegisterScanResult(
        event: ScanEvent(
          id: eventId,
          sessionId: sessionId,
          productCode: productCode,
          codeType: codeType,
          raw: raw,
          serialNumber: serialNumber,
          lot: lot,
          expiry: _parseExpiryIso(expiryIso),
          createdAt: now,
          isDeleted: false,
        ),
        wasDuplicateSerial: false,
      );
    });
  }

  @override
  Future<List<InventoryItem>> listItems(String sessionId) async {
    final countExpr = db.scanEvents.id.count();
    final lastExpr = db.scanEvents.createdAt.max();
    final query = db.selectOnly(db.scanEvents)
      ..addColumns([
        db.scanEvents.productCode,
        db.scanEvents.codeType,
        countExpr,
        lastExpr,
      ])
      ..where(
        db.scanEvents.sessionId.equals(sessionId) &
            db.scanEvents.isDeleted.equals(false),
      )
      ..groupBy([db.scanEvents.productCode, db.scanEvents.codeType])
      ..orderBy([OrderingTerm.desc(lastExpr)]);

    final rows = await query.get();
    return rows.map((row) {
      final productCode = row.read(db.scanEvents.productCode)!;
      final codeType = row.read(db.scanEvents.codeType)!;
      final qty = row.read(countExpr) ?? 0;
      final lastScanAt =
          row.read(lastExpr) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return InventoryItem(
        id: '$productCode|$codeType',
        sessionId: sessionId,
        productCode: productCode,
        codeType: codeType,
        qty: qty,
        lastScanAt: lastScanAt,
      );
    }).toList();
  }

  @override
  Future<List<ScanEvent>> listEventsForSession(String sessionId) async {
    final rows =
        await (db.select(db.scanEvents)
              ..where((t) => t.sessionId.equals(sessionId))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.asc,
                ),
              ]))
            .get();
    return rows.map(_mapEvent).toList();
  }

  @override
  Future<List<ScanEvent>> listRecentEvents(
    String sessionId, {
    int limit = 50,
  }) async {
    final rows =
        await (db.select(db.scanEvents)
              ..where((t) => t.sessionId.equals(sessionId))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(limit))
            .get();
    return rows.map(_mapEvent).toList();
  }

  @override
  Future<List<ScanEvent>> listEventsForProduct(
    String sessionId,
    String productCode,
  ) async {
    final rows =
        await (db.select(db.scanEvents)
              ..where(
                (t) =>
                    t.sessionId.equals(sessionId) &
                    t.productCode.equals(productCode),
              )
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return rows.map(_mapEvent).toList();
  }

  @override
  Future<bool> deleteEvent(String eventId) async {
    final now = DateTime.now();
    final updated =
        await (db.update(db.scanEvents)
              ..where((t) => t.id.equals(eventId) & t.isDeleted.equals(false)))
            .write(ScanEventsCompanion(isDeleted: const Value(true)));
    if (updated > 0) {
      final event = await (db.select(
        db.scanEvents,
      )..where((t) => t.id.equals(eventId))).getSingle();
      await _touchSession(event.sessionId, now);
      return true;
    }
    return false;
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
    return db.transaction(() async {
      final rows =
          await (db.select(db.scanEvents)
                ..where(
                  (t) =>
                      t.sessionId.equals(sessionId) &
                      t.productCode.equals(productCode) &
                      t.isDeleted.equals(false),
                )
                ..orderBy([
                  (t) => OrderingTerm(
                    expression: t.createdAt,
                    mode: OrderingMode.desc,
                  ),
                ])
                ..limit(count))
              .get();
      if (rows.isEmpty) {
        return 0;
      }
      final ids = rows.map((row) => row.id).toList();
      await (db.update(db.scanEvents)..where((t) => t.id.isIn(ids))).write(
        const ScanEventsCompanion(isDeleted: Value(true)),
      );
      await _touchSession(sessionId, DateTime.now());
      return ids.length;
    });
  }

  @override
  Future<int> deleteAllEventsForProduct(
    String sessionId,
    String productCode,
  ) async {
    final updated =
        await (db.update(db.scanEvents)..where(
              (t) =>
                  t.sessionId.equals(sessionId) &
                  t.productCode.equals(productCode) &
                  t.isDeleted.equals(false),
            ))
            .write(const ScanEventsCompanion(isDeleted: Value(true)));
    if (updated > 0) {
      await _touchSession(sessionId, DateTime.now());
    }
    return updated;
  }

  ScanEvent _mapEvent(ScanEventRow row) {
    return ScanEvent(
      id: row.id,
      sessionId: row.sessionId,
      productCode: row.productCode,
      codeType: row.codeType,
      raw: row.raw,
      serialNumber: row.serialNumber,
      lot: row.lot,
      expiry: _parseExpiryIso(row.expiry),
      createdAt: row.createdAt,
      isDeleted: row.isDeleted,
    );
  }

  String? _expiryToIsoDate(DateTime? expiry) {
    if (expiry == null) {
      return null;
    }
    return expiry.toIso8601String().substring(0, 10);
  }

  DateTime? _parseExpiryIso(String? expiry) {
    if (expiry == null || expiry.isEmpty) {
      return null;
    }
    return DateTime.tryParse(expiry);
  }
}
