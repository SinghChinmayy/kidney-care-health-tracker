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
  static const Color background = Colors.white;
  static const Color ink = Colors.black;
  static const Color surfaceMuted = Color(0xFFF9FAFB);
  /// Soft fill for home summary cards (modern rounded tiles).
  static const Color cardSurface = Color(0xFFF2F2F2);
  static const Color muted = Color(0xFF6B7280);
  static const Color logBloodPressure = Color(0xFFE57373);
  static const Color logBloodGlucose = Color(0xFF64B5F6);
  static const Color logWeight = Color(0xFF4DB6AC);
  static const Color logFluidIntake = Color(0xFF4FC3F7);
  static Color get error => Colors.red.shade700;

  static const double spacingXs = 8;
  static const double spacingSm = 16;
  static const double spacingMd = 24;
  static const double spacingLg = 32;
  static const double spacingXl = 40;

  static const double formMaxWidth = 400;
  static const double cornerRadius = 8;
  /// Large radius for soft home / dashboard cards.
  static const double cardCornerRadius = 24;

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
        onPrimary: background,
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
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
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
