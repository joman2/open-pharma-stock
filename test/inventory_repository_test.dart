import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/features/inventory/data/in_memory_inventory_repository.dart';

void main() {
  group('InMemoryInventoryRepository serial dedupe', () {
    test('same serial does not increment qty', () async {
      final repository = InMemoryInventoryRepository();
      final session = await repository.createSession('Sessao 1');

      await repository.registerScan(
        sessionId: session.id,
        raw: '010123456789012821SERIAL001',
      );
      await repository.registerScan(
        sessionId: session.id,
        raw: '010123456789012821SERIAL001',
      );

      final items = await repository.listItems(session.id);
      expect(items, hasLength(1));
      expect(items.first.qty, 1);
    });

    test('different serial increments qty', () async {
      final repository = InMemoryInventoryRepository();
      final session = await repository.createSession('Sessao 2');

      await repository.registerScan(
        sessionId: session.id,
        raw: '010123456789012821SERIAL001',
      );
      await repository.registerScan(
        sessionId: session.id,
        raw: '010123456789012821SERIAL002',
      );

      final items = await repository.listItems(session.id);
      expect(items, hasLength(1));
      expect(items.first.qty, 2);
    });

    test('ean increments every time', () async {
      final repository = InMemoryInventoryRepository();
      final session = await repository.createSession('Sessao 3');

      await repository.registerScan(
        sessionId: session.id,
        raw: '7891234567890',
      );
      await repository.registerScan(
        sessionId: session.id,
        raw: '7891234567890',
      );

      final items = await repository.listItems(session.id);
      expect(items, hasLength(1));
      expect(items.first.qty, 2);
    });

    test('session override for barcode quantity can be updated', () async {
      final repository = InMemoryInventoryRepository();
      final session = await repository.createSession(
        'Sessao 4',
        barcodeQuantityPromptEnabled: true,
      );

      expect(session.barcodeQuantityPromptEnabled, isTrue);

      final updated = await repository.updateSessionBarcodeQuantityPrompt(
        session.id,
        false,
      );

      expect(updated.barcodeQuantityPromptEnabled, isFalse);
      final loaded = await repository.getSession(session.id);
      expect(loaded?.barcodeQuantityPromptEnabled, isFalse);
    });
  });
}
