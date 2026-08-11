import 'package:flutter/material.dart';

final class AppPalette {
  static const Color background = Color(0xFF191B1F);
  static const Color backgroundRaised = Color(0xFF1F2227);
  static const Color surface = Color(0xFF23262C);
  static const Color surfaceMuted = Color(0xFF2B2F36);
  static const Color surfaceStrong = Color(0xFF111317);
  static const Color cardBorder = Color(0xFF2D3138);
  static const Color textPrimary = Color(0xFFF4F5F7);
  static const Color textSecondary = Color(0xFFB7BBC7);
  static const Color textMuted = Color(0xFF7F8695);
  static const Color accent = Color(0xFFC9DCF7);
  static const Color accentStrong = Color(0xFF9FC3F1);
  static const Color accentInk = Color(0xFF113A62);
  static const Color warning = Color(0xFF544724);
  static const Color warningText = Color(0xFFFFC44D);
  static const Color success = Color(0xFF0CCB8E);
  static const Color danger = Color(0xFFF36A6A);

  const AppPalette._();
}

final class AppPaletteTokens {
  const AppPaletteTokens();

  Color get background => AppPalette.background;
  Color get backgroundRaised => AppPalette.backgroundRaised;
  Color get surface => AppPalette.surface;
  Color get surfaceMuted => AppPalette.surfaceMuted;
  Color get surfaceStrong => AppPalette.surfaceStrong;
  Color get cardBorder => AppPalette.cardBorder;
  Color get textPrimary => AppPalette.textPrimary;
  Color get textSecondary => AppPalette.textSecondary;
  Color get textMuted => AppPalette.textMuted;
  Color get accent => AppPalette.accent;
  Color get accentStrong => AppPalette.accentStrong;
  Color get accentInk => AppPalette.accentInk;
  Color get warning => AppPalette.warning;
  Color get warningText => AppPalette.warningText;
  Color get success => AppPalette.success;
  Color get danger => AppPalette.danger;
}

ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: AppPalette.accent,
    onPrimary: AppPalette.accentInk,
    secondary: AppPalette.accentStrong,
    onSecondary: AppPalette.accentInk,
    error: AppPalette.danger,
    onError: Colors.white,
    surface: AppPalette.surface,
    onSurface: AppPalette.textPrimary,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppPalette.background,
  );

  final textTheme = base.textTheme.copyWith(
    headlineMedium: base.textTheme.headlineMedium?.copyWith(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: scheme.onSurface,
      letterSpacing: -0.8,
    ),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: scheme.onSurface,
      letterSpacing: -0.6,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: scheme.onSurface,
      letterSpacing: -0.4,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    titleSmall: base.textTheme.titleSmall?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(
      fontSize: 16,
      color: AppPalette.textSecondary,
      height: 1.35,
    ),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      color: AppPalette.textSecondary,
      height: 1.35,
    ),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      color: AppPalette.textMuted,
    ),
    labelLarge: base.textTheme.labelLarge?.copyWith(
      fontSize: 16,
      color: AppPalette.textPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
    labelMedium: base.textTheme.labelMedium?.copyWith(
      fontSize: 12,
      color: AppPalette.accent,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.3,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: const IconThemeData(color: AppPalette.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppPalette.backgroundRaised,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    dividerColor: AppPalette.cardBorder,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppPalette.accent,
        foregroundColor: AppPalette.accentInk,
        minimumSize: const Size.fromHeight(62),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: textTheme.titleMedium,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: const BorderSide(color: AppPalette.cardBorder),
        minimumSize: const Size.fromHeight(62),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: textTheme.titleMedium,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppPalette.accent,
      foregroundColor: AppPalette.accentInk,
      sizeConstraints: const BoxConstraints.tightFor(width: 68, height: 68),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.surface,
      hintStyle: const TextStyle(color: AppPalette.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppPalette.accentStrong,
          width: 1.5,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return AppPalette.textPrimary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppPalette.accentStrong;
        }
        return const Color(0xFF525866);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppPalette.surfaceStrong,
      contentTextStyle: const TextStyle(color: AppPalette.textPrimary),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

extension AppThemeContext on BuildContext {
  AppPaletteTokens get palette => const AppPaletteTokens();

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  double get uiScale {
    final width = MediaQuery.sizeOf(this).width;
    return (width / 390).clamp(0.98, 1.12);
  }

  double s(double value) => value * uiScale;
}
