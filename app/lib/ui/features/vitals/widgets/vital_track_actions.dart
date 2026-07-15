import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class VitalTrackActions extends StatelessWidget {
  const VitalTrackActions({
    super.key,
    required this.onSave,
    required this.onClear,
    this.saveLabel = 'Save',
    this.clearLabel = 'Clear',
    this.saveColor = AppTheme.logWeight,
    this.isSaving = false,
  });

  final VoidCallback? onSave;
  final VoidCallback onClear;
  final String saveLabel;
  final String clearLabel;
  final Color saveColor;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: saveColor,
              foregroundColor: AppTheme.cardSurface,
              disabledBackgroundColor: saveColor.withValues(alpha: 0.5),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.cardSurface,
                    ),
                  )
                : Text(
                    saveLabel.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: OutlinedButton(
            onPressed: isSaving ? null : onClear,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.logBloodGlucose,
              side: const BorderSide(color: AppTheme.logBloodGlucose),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
              ),
            ),
            child: Text(
              clearLabel.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
