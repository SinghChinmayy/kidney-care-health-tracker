import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Brief, muted confirmation after a vital reading is saved.
void showVitalSavedConfirmation(
  BuildContext context, {
  String message = 'Reading saved',
  Color accentColor = AppTheme.logWeight,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_rounded,
              size: 18,
              color: accentColor,
            ),
            const SizedBox(width: AppTheme.spacingXs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceMuted,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          AppTheme.spacingSm,
          0,
          AppTheme.spacingSm,
          AppTheme.spacingSm,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingXs + 4,
        ),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
          side: BorderSide(color: accentColor.withValues(alpha: 0.35)),
        ),
      ),
    );
}
