import 'package:flutter/material.dart';

import 'app_tour_scope.dart';

enum AppTourTargetId {
  sessionsSettingsButton,
  sessionsNewSessionFab,
  sessionsSessionList,
  sessionsFirstSessionCard,
  inventorySearchButton,
  inventorySearchField,
  inventoryExportButton,
  inventoryMenuButton,
  inventoryScannerFab,
  inventorySummaryStrip,
  inventoryFilterChips,
  inventoryModeTabs,
  inventoryProductsList,
  inventoryReadsList,
  inventoryScannerModeDataMatrix,
  inventoryScannerModeBarcode,
  inventoryScannerPauseButton,
  inventoryScannerTorchButton,
  inventoryScannerCloseButton,
  settingsTourReplayButton,
  settingsTourAutoStartToggle,
  settingsCatalogImportButton,
  settingsCatalogStateCard,
  productDetailMetadataCard,
  productDetailExternalLinksRow,
  productDetailTimelineList,
  productDetailDeleteAction,
  exportFormatSection,
  exportModeSection,
  exportPreviewSection,
  exportSaveButton,
}

class AppTourTargets {
  AppTourTargets()
    : _keys = {
        for (final id in AppTourTargetId.values)
          id: GlobalKey(debugLabel: id.name),
      };

  final Map<AppTourTargetId, GlobalKey> _keys;

  GlobalKey keyOf(AppTourTargetId id) => _keys[id]!;

  BuildContext? contextOf(AppTourTargetId id) => keyOf(id).currentContext;

  Rect? rectOf(AppTourTargetId id) {
    final context = contextOf(id);
    if (context == null) {
      return null;
    }
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & renderObject.size;
  }
}

class TourTargetAnchor extends StatelessWidget {
  const TourTargetAnchor({
    super.key,
    required this.targetId,
    required this.child,
  });

  final AppTourTargetId targetId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = AppTourScope.maybeOf(context);
    if (controller == null) {
      return child;
    }
    return SizedBox(key: controller.targets.keyOf(targetId), child: child);
  }
}
