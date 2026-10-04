import 'package:flutter/material.dart';

class AppTheme {
  static const Color ink = Color(0xFF20203A);
  static const Color purple = Color(0xFF5B3CC4);
  static const Color green = Color(0xFF116B50);
  static const Color canvas = Color(0xFFF7F6FC);

  static ThemeData light() => _make(Brightness.light);
  static ThemeData dark() => _make(Brightness.dark);

  static ThemeData _make(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: purple,
      brightness: brightness,
      primary: brightness == Brightness.light
          ? purple
          : const Color(0xFFBDAAFF),
      secondary: brightness == Brightness.light
          ? green
          : const Color(0xFF91D6B7),
      surface: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF191824),
      error: brightness == Brightness.light
          ? const Color(0xFFB3261E)
          : const Color(0xFFFFB4AB),
    );
    final isLight = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isLight ? canvas : const Color(0xFF11111A),
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? canvas : const Color(0xFF11111A),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: isLight ? 1 : 0,
        shadowColor: const Color(0x1A292050),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.42),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: isLight ? ink : const Color(0xFFF5F1FF),
        displayColor: isLight ? ink : const Color(0xFFF5F1FF),
      ),
    );
  }
}
