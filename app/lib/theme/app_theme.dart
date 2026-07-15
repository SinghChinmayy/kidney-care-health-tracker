import 'package:flutter/material.dart';

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

class AppTheme {
  /// Global page / scaffold background.
  static const Color background = Color(0xFFFFFFFF);
  static const Color ink = Colors.black;
  static const Color surfaceMuted = Color(0xFFF9FAFB);
  /// Alias for [background]; prefer [background] for new code.
  static const Color bpBackground = background;
  /// Soft white fill for cards, sheets, and selected controls.
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF6B7280);
  static const Color logBloodPressure = Color(0xFFE57373);
  static const Color logBloodGlucose = Color(0xFF64B5F6);
  static const Color logWeight = Color(0xFF4DB6AC);
  static const Color logFluidIntake = Color(0xFF4FC3F7);
  static Color get error => Colors.red.shade700;

  /// Hairline border that reads on cream / off-white backgrounds.
  static Color get cardBorder => ink.withValues(alpha: 0.12);

  static BoxDecoration homeCardDecoration({
    Color? color,
    double radius = cardCornerRadius,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: color ?? cardSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  static const double spacingXs = 8;
  static const double spacingSm = 16;
  static const double spacingMd = 24;
  static const double spacingLg = 32;
  static const double spacingXl = 40;

  static const double formMaxWidth = 400;
  static const double cornerRadius = 8;
  /// Large radius for soft home / dashboard cards.
  static const double cardCornerRadius = 24;

  /// Bottom inset so scroll content clears the floating pill nav.
  static const double floatingNavClearance = 96;

  static const TextStyle optionCardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ink,
  );

  static ButtonStyle optionCardButtonStyle({EdgeInsetsGeometry? padding}) {
    return OutlinedButton.styleFrom(
      foregroundColor: ink,
      side: const BorderSide(color: ink),
      padding: padding ?? const EdgeInsets.all(spacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      alignment: Alignment.centerLeft,
    );
  }

  static ButtonStyle secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: ink,
      side: const BorderSide(color: ink),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
    );
  }

  static BoxDecoration readingCardDecoration = BoxDecoration(
    border: Border.all(color: ink),
    borderRadius: BorderRadius.circular(cornerRadius),
  );

  static const BorderRadius sheetTopRadius = BorderRadius.vertical(
    top: Radius.circular(16),
  );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        surface: background,
        onSurface: ink,
        primary: ink,
        onPrimary: cardSurface,
        error: Colors.red,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
        },
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: ink,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          color: ink,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: background,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ink),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: ink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(color: cardBorder, width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ink,
        foregroundColor: background,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: background),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          borderSide: const BorderSide(color: ink, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          borderSide: const BorderSide(color: ink, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          borderSide: const BorderSide(color: ink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          borderSide: BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          borderSide: BorderSide(color: error, width: 2),
        ),
        errorStyle: TextStyle(color: error),
      ),
    );
  }
}
