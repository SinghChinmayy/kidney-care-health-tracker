import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
import 'package:app/ui/features/vitals/view_models/blood_pressure_view_model.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_forms.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_menu_sheet.dart';
import 'package:app/ui/features/vitals/widgets/vital_save_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showBloodPressureLogSheet(
  BuildContext context, {
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.background,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      final viewModel = sheetContext.read<BloodPressureViewModel>();
      return _VitalLogSheetPadding(
        child: AddBloodPressureForm(
          onSubmit: (systolic, diastolic, heartRate, notes) async {
            await viewModel.addReading(
              systolic: systolic,
              diastolic: diastolic,
              heartRateBpm: heartRate,
              notes: notes,
            );
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
            if (context.mounted) {
              showVitalSavedConfirmation(
                context,
                message: 'Blood pressure saved',
                accentColor: AppTheme.logBloodPressure,
              );
            }
            onSaved?.call();
          },
        ),
      );
    },
  );
}

Future<void> showBloodGlucoseLogSheet(
  BuildContext context, {
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.background,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      final viewModel = sheetContext.read<BloodGlucoseViewModel>();
      return _VitalLogSheetPadding(
        child: AddBloodGlucoseForm(
          contextOptions: bloodGlucoseContextOptions,
          onSubmit: (value, readingContext, notes) async {
            await viewModel.addReading(
              valueMgDl: value,
              context: readingContext,
              notes: notes,
            );
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
            if (context.mounted) {
              showVitalSavedConfirmation(
                context,
                message: 'Blood glucose saved',
                accentColor: AppTheme.logBloodGlucose,
              );
            }
            onSaved?.call();
          },
        ),
      );
    },
  );
}

Future<void> showWeightLogSheet(
  BuildContext context, {
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.background,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      final viewModel = sheetContext.read<WeightViewModel>();
      return _VitalLogSheetPadding(
        child: AddWeightForm(
          onSubmit: (valueKg, dialysisTiming, weightContext, notes) async {
            await viewModel.addReading(
              valueKg: valueKg,
              dialysisTiming: dialysisTiming,
              weightContext: weightContext,
              notes: notes,
            );
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
            if (context.mounted) {
              showVitalSavedConfirmation(
                context,
                message: 'Weight saved',
                accentColor: AppTheme.logWeight,
              );
            }
            onSaved?.call();
          },
        ),
      );
    },
  );
}

Future<void> showVitalLogSheet(
  BuildContext context,
  VitalLogType type, {
  VoidCallback? onSaved,
}) {
  return switch (type) {
    VitalLogType.bloodPressure => showBloodPressureLogSheet(
        context,
        onSaved: onSaved,
      ),
    VitalLogType.bloodGlucose => showBloodGlucoseLogSheet(
        context,
        onSaved: onSaved,
      ),
    VitalLogType.weight => showWeightLogSheet(context, onSaved: onSaved),
  };
}

class _VitalLogSheetPadding extends StatelessWidget {
  const _VitalLogSheetPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingSm,
        right: AppTheme.spacingSm,
        top: AppTheme.spacingSm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingSm,
      ),
      child: child,
    );
  }
}
