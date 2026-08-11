import 'package:flutter/foundation.dart';

import 'app_tour_targets.dart';

enum AppTourPage { sessions, inventory, export, settings, productDetail }

enum AppTourStartOrigin { automatic, manualReplay }

enum AppTourActionId {
  openSearch,
  openScanner,
  closeScanner,
  showProductsTab,
  showReadsTab,
  openExport,
}

@immutable
class AppTourStep {
  const AppTourStep({
    required this.id,
    required this.page,
    required this.title,
    required this.description,
    this.targetId,
    this.enterActionId,
    this.allowBack = true,
    this.nextLabel = 'Seguinte',
  });

  final String id;
  final AppTourPage page;
  final String title;
  final String description;
  final AppTourTargetId? targetId;
  final AppTourActionId? enterActionId;
  final bool allowBack;
  final String nextLabel;
}

@immutable
class AppTourState {
  const AppTourState({
    this.isActive = false,
    this.isBusy = false,
    this.stepIndex = 0,
    this.steps = const <AppTourStep>[],
    this.origin,
  });

  final bool isActive;
  final bool isBusy;
  final int stepIndex;
  final List<AppTourStep> steps;
  final AppTourStartOrigin? origin;

  AppTourStep? get currentStep {
    if (!isActive || stepIndex < 0 || stepIndex >= steps.length) {
      return null;
    }
    return steps[stepIndex];
  }

  bool get hasPrevious => isActive && stepIndex > 0;

  AppTourState copyWith({
    bool? isActive,
    bool? isBusy,
    int? stepIndex,
    List<AppTourStep>? steps,
    AppTourStartOrigin? origin,
    bool clearOrigin = false,
  }) {
    return AppTourState(
      isActive: isActive ?? this.isActive,
      isBusy: isBusy ?? this.isBusy,
      stepIndex: stepIndex ?? this.stepIndex,
      steps: steps ?? this.steps,
      origin: clearOrigin ? null : (origin ?? this.origin),
    );
  }
}
