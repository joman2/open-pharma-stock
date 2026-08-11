import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'app_tour_scope.dart';
import 'app_tour_state.dart';

class AppTourOverlay extends StatelessWidget {
  const AppTourOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = AppTourScope.maybeOf(context);
    if (controller == null) {
      return child;
    }

    return ValueListenableBuilder<AppTourState>(
      valueListenable: controller,
      builder: (context, state, _) {
        final step = state.currentStep;
        final targetRect = step?.targetId == null
            ? null
            : controller.targets.rectOf(step!.targetId!);

        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (state.isActive && step != null) ...[
              IgnorePointer(
                child: CustomPaint(
                  painter: _TourScrimPainter(highlightRect: targetRect),
                  child: const SizedBox.expand(),
                ),
              ),
              if (targetRect != null)
                Positioned.fromRect(
                  rect: targetRect.inflate(8),
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppPalette.accent, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x663D7DBE),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              _TourStepCard(
                step: step,
                stepIndex: state.stepIndex,
                stepCount: state.steps.length,
                targetRect: targetRect,
                isBusy: state.isBusy,
                canGoBack: step.allowBack && state.hasPrevious,
                onBack: controller.previous,
                onNext: state.stepIndex == state.steps.length - 1
                    ? controller.complete
                    : controller.next,
                onSkip: controller.skip,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TourStepCard extends StatelessWidget {
  const _TourStepCard({
    required this.step,
    required this.stepIndex,
    required this.stepCount,
    required this.targetRect,
    required this.isBusy,
    required this.canGoBack,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  final AppTourStep step;
  final int stepIndex;
  final int stepCount;
  final Rect? targetRect;
  final bool isBusy;
  final bool canGoBack;
  final Future<void> Function() onBack;
  final Future<void> Function() onNext;
  final Future<void> Function() onSkip;

  static final FocusNode _skipFocusNode = FocusNode(
    debugLabel: 'tourSkipButton',
  );
  static final FocusNode _backFocusNode = FocusNode(
    debugLabel: 'tourBackButton',
  );
  static final FocusNode _nextFocusNode = FocusNode(
    debugLabel: 'tourNextButton',
  );

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final handleKeysLocally =
        Theme.of(context).platform != TargetPlatform.android;
    final width = math.min(mediaSize.width - 32, 420.0);
    final cardRect = _resolveCardRect(mediaSize, width, _estimatedCardHeight());

    return Positioned(
      left: cardRect.left,
      top: cardRect.top,
      width: cardRect.width,
      child: Focus(
        autofocus: true,
        canRequestFocus: true,
        onKeyEvent: (node, event) {
          if (!handleKeysLocally || event is! KeyDownEvent || isBusy) {
            return KeyEventResult.ignored;
          }

          final key = event.logicalKey;
          if (_isNextKey(key)) {
            onNext();
            return KeyEventResult.handled;
          }
          if (canGoBack && _isPreviousKey(key)) {
            onBack();
            return KeyEventResult.handled;
          }
          if (_isSkipKey(key)) {
            onSkip();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Shortcuts(
            shortcuts: handleKeysLocally
                ? const <ShortcutActivator, Intent>{
                    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                    SingleActivator(LogicalKeyboardKey.numpadEnter):
                        ActivateIntent(),
                    SingleActivator(LogicalKeyboardKey.select):
                        ActivateIntent(),
                    SingleActivator(LogicalKeyboardKey.gameButtonA):
                        ActivateIntent(),
                  }
                : const <ShortcutActivator, Intent>{},
            child: Material(
              color: AppPalette.backgroundRaised,
              elevation: 16,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Passo ${stepIndex + 1} de $stepCount',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      step.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        focusNode: _skipFocusNode,
                        onPressed: isBusy ? null : () => onSkip(),
                        child: const Text('Ignorar'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (canGoBack) ...[
                          Expanded(
                            child: OutlinedButton(
                              focusNode: _backFocusNode,
                              onPressed: isBusy ? null : () => onBack(),
                              child: const Text('Anterior'),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: FilledButton(
                            autofocus: true,
                            focusNode: _nextFocusNode,
                            onPressed: isBusy ? null : () => onNext(),
                            child: Text(step.nextLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _estimatedCardHeight() {
    return canGoBack ? 286.0 : 258.0;
  }

  bool _isNextKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.arrowRight;
  }

  bool _isPreviousKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.browserBack;
  }

  bool _isSkipKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace;
  }

  Rect _resolveCardRect(Size mediaSize, double width, double cardHeight) {
    final horizontal = (mediaSize.width - width) / 2;
    if (targetRect == null) {
      final top = math.max(96.0, mediaSize.height * 0.55 - (cardHeight / 2));
      return Rect.fromLTWH(horizontal, top, width, cardHeight);
    }

    final isNearTop = targetRect!.top < 140;
    final isWideTarget = targetRect!.width > width * 0.55;
    final verticalGap = isNearTop ? 52.0 : 20.0;
    final spaceBelow = mediaSize.height - targetRect!.bottom;
    final shouldPlaceBelow =
        isNearTop || spaceBelow > cardHeight + verticalGap + 28;
    final preferredTop = shouldPlaceBelow
        ? targetRect!.bottom + verticalGap
        : targetRect!.top - cardHeight - verticalGap;
    final top = preferredTop.clamp(72.0, mediaSize.height - cardHeight - 24.0);
    final availableLeft = 16.0;
    final availableRight = mediaSize.width - width - 16.0;
    final centerLeft = targetRect!.center.dx - (width / 2);
    final left = isNearTop || isWideTarget
        ? centerLeft
        : targetRect!.center.dx <= mediaSize.width * 0.33
        ? targetRect!.left
        : targetRect!.center.dx >= mediaSize.width * 0.67
        ? targetRect!.right - width
        : centerLeft;

    return Rect.fromLTWH(
      left.clamp(availableLeft, availableRight),
      top,
      width,
      cardHeight,
    );
  }
}

class _TourScrimPainter extends CustomPainter {
  const _TourScrimPainter({required this.highlightRect});

  final Rect? highlightRect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.76);
    final fullPath = Path()..addRect(Offset.zero & size);
    if (highlightRect == null) {
      canvas.drawPath(fullPath, overlay);
      return;
    }

    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          highlightRect!.inflate(12),
          const Radius.circular(24),
        ),
      );
    final path = Path.combine(PathOperation.difference, fullPath, holePath);
    canvas.drawPath(path, overlay);
  }

  @override
  bool shouldRepaint(covariant _TourScrimPainter oldDelegate) {
    return oldDelegate.highlightRect != highlightRect;
  }
}
