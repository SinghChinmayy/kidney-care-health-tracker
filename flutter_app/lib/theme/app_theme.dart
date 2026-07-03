import 'package:flutter/material.dart';

/// Central app theme.
///
/// Kept intentionally monochrome (black/white) with a single functional
/// red for error states, per `docs/Design/design.md` — no color palette
/// has been decided yet beyond that. Update both this file and the design
/// doc together whenever a new global style decision is made.
class AppTheme {
  AppTheme._();

  static const Color background = Colors.white;
  static const Color ink = Colors.black;
  static final Color error = Colors.red.shade700;

  static const double borderRadius = 8;
  static const double spacingXs = 8;
  static const double spacingSm = 16;
  static const double spacingMd = 24;
  static const double spacingLg = 32;
  static const double spacingXl = 40;

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: ink,
      onPrimary: background,
      secondary: ink,
      onSecondary: background,
      error: error,
      onError: background,
      surface: background,
      onSurface: ink,
    ),
    // App-wide "no animations for now" principle, enforced at the
    // navigation level: route transitions are instant, no slide/fade.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
        TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
      },
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: ink,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(color: ink, fontSize: 14),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: ink),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: ink),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: ink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: error, width: 2),
      ),
      labelStyle: const TextStyle(color: ink),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: background,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ink),
    ),
  );
}

/// A [PageTransitionsBuilder] that performs no transition animation at all,
/// so route pushes/pops are instant. Used app-wide to match the "no
/// animations for now" design principle.
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
