import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
import 'package:app/ui/features/vitals/view_models/blood_pressure_view_model.dart';
import 'package:app/ui/features/vitals/view_models/fluid_intake_view_model.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_forms.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_menu_sheet.dart';
import 'package:app/ui/features/vitals/widgets/vital_save_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showBloodPressureLogSheet(
  BuildContext context, {
  DateTime? initialRecordedAt,
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
          initialRecordedAt: initialRecordedAt,
          onSubmit: (systolic, diastolic, heartRate, recordedAt) async {
            await viewModel.addReading(
              systolic: systolic,
              diastolic: diastolic,
              heartRateBpm: heartRate,
              recordedAt: recordedAt,
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
  DateTime? initialRecordedAt,
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
          initialRecordedAt: initialRecordedAt,
          onSubmit: (value, readingContext, recordedAt) async {
            await viewModel.addReading(
              valueMgDl: value,
              context: readingContext,
              recordedAt: recordedAt,
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
  DateTime? initialRecordedAt,
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
              recordedAt: initialRecordedAt,
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

Future<void> showFluidIntakeLogSheet(
  BuildContext context, {
  DateTime? initialRecordedAt,
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
      final viewModel = sheetContext.read<FluidIntakeViewModel>();
      return _VitalLogSheetPadding(
        child: AddFluidIntakeForm(
          initialRecordedAt: initialRecordedAt,
          onSubmit: (fluidMl, recordedAt) async {
            await viewModel.addLog(
              fluidMl: fluidMl,
              recordedAt: recordedAt,
            );
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
            if (context.mounted) {
              showVitalSavedConfirmation(
                context,
                message: 'Water intake saved',
                accentColor: AppTheme.logFluidIntake,
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
  DateTime? initialRecordedAt,
  VoidCallback? onSaved,
}) {
  return switch (type) {
    VitalLogType.bloodPressure => showBloodPressureLogSheet(
        context,
        initialRecordedAt: initialRecordedAt,
        onSaved: onSaved,
      ),
    VitalLogType.bloodGlucose => showBloodGlucoseLogSheet(
        context,
        initialRecordedAt: initialRecordedAt,
        onSaved: onSaved,
      ),
    VitalLogType.weight => showWeightLogSheet(
        context,
        initialRecordedAt: initialRecordedAt,
        onSaved: onSaved,
      ),
    VitalLogType.fluidIntake => showFluidIntakeLogSheet(
        context,
        initialRecordedAt: initialRecordedAt,
        onSaved: onSaved,
      ),
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
