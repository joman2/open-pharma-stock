import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/app/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('AppSettingsController loads persisted tutorial flags', () async {
    SharedPreferences.setMockInitialValues({
      'tour.has_seen_any_tour': true,
      'tour.auto_start_enabled': false,
      'tour.last_completed_version': 1,
      'tour.last_dismissed_version': 0,
    });

    final preferences = await SharedPreferences.getInstance();
    final controller = AppSettingsController(preferences: preferences);

    expect(controller.value.hasSeenAnyTour, isTrue);
    expect(controller.value.tourAutoStartEnabled, isFalse);
    expect(controller.value.lastCompletedTourVersion, 1);
    expect(controller.value.lastDismissedTourVersion, 0);
    expect(controller.value.shouldAutoStartTour, isFalse);
  });

  test('markTourCompleted persists completion and clears dismissal', () async {
    SharedPreferences.setMockInitialValues({'tour.last_dismissed_version': 1});

    final preferences = await SharedPreferences.getInstance();
    final controller = AppSettingsController(preferences: preferences);

    await controller.markTourCompleted();

    expect(controller.value.hasSeenAnyTour, isTrue);
    expect(
      controller.value.lastCompletedTourVersion,
      AppSettingsState.currentTourVersion,
    );
    expect(controller.value.lastDismissedTourVersion, isNull);
    expect(
      preferences.getInt('tour.last_completed_version'),
      AppSettingsState.currentTourVersion,
    );
    expect(preferences.getInt('tour.last_dismissed_version'), isNull);
  });

  test(
    'markTourDismissed persists dismissal without changing auto-start',
    () async {
      SharedPreferences.setMockInitialValues({
        'tour.auto_start_enabled': false,
      });

      final preferences = await SharedPreferences.getInstance();
      final controller = AppSettingsController(preferences: preferences);

      await controller.markTourDismissed();

      expect(controller.value.hasSeenAnyTour, isTrue);
      expect(
        controller.value.lastDismissedTourVersion,
        AppSettingsState.currentTourVersion,
      );
      expect(controller.value.tourAutoStartEnabled, isFalse);
      expect(
        preferences.getInt('tour.last_dismissed_version'),
        AppSettingsState.currentTourVersion,
      );
    },
  );

  test('barcode quantity prompt default is persisted', () async {
    SharedPreferences.setMockInitialValues({});

    final preferences = await SharedPreferences.getInstance();
    final controller = AppSettingsController(preferences: preferences);

    expect(controller.value.barcodeQuantityPromptByDefault, isFalse);

    await controller.setBarcodeQuantityPromptByDefault(true);

    expect(controller.value.barcodeQuantityPromptByDefault, isTrue);
    expect(
      preferences.getBool('scanner.barcode_quantity_prompt_by_default'),
      isTrue,
    );
  });

  test('online catalogue lookup is opt-in and persisted', () async {
    SharedPreferences.setMockInitialValues({});

    final preferences = await SharedPreferences.getInstance();
    final controller = AppSettingsController(preferences: preferences);

    expect(controller.value.onlineCatalogLookupEnabled, isFalse);

    await controller.setOnlineCatalogLookupEnabled(true);

    expect(controller.value.onlineCatalogLookupEnabled, isTrue);
    expect(preferences.getBool('catalog.online_lookup_enabled'), isTrue);
  });
}
