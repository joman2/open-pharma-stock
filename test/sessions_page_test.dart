import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/app/settings/app_settings.dart';
import 'package:open_pharma_stock/app/settings/settings_scope.dart';
import 'package:open_pharma_stock/features/inventory/data/in_memory_inventory_repository.dart';
import 'package:open_pharma_stock/features/inventory/presentation/sessions_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('NewSessionPage creates a session when submitting a valid name', (
    tester,
  ) async {
    final repository = InMemoryInventoryRepository();
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final settings = AppSettingsController(preferences: preferences);

    await tester.pumpWidget(
      SettingsScope(
        controller: settings,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: NewSessionPage(repository: repository),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Prateleira A1');
    await tester.tap(find.text('Começar contagem'));
    await tester.pumpAndSettle();

    final sessions = await repository.listSessions();
    expect(sessions, hasLength(1));
    expect(sessions.single.name, 'Prateleira A1');
  });
}
