import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_context_picker.dart';
import 'package:app/ui/features/vitals/widgets/date_grouped_history_list.dart';
import 'package:app/ui/features/vitals/widgets/weight_history_row.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BloodGlucoseHistoryTab extends StatelessWidget {
  const BloodGlucoseHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BloodGlucoseViewModel>();

    return WeightHistoryListContainer(
      child: DateGroupedHistoryList(
        readings: viewModel.readings,
        recordedAt: (reading) => reading.recordedAt,
        emptyMessage: 'No readings yet.\nSwitch to Track to log one.',
        accentColor: AppTheme.logBloodGlucose,
        rowBuilder: (context, reading) {
          final contextLabel = reading.context == null
              ? null
              : formatBloodGlucoseContextLabel(reading.context!);

          return VitalHistoryRow(
            primaryText: reading.displayValue,
            secondaryText: formatHistoryTime(reading.recordedAt),
            notes: contextLabel ?? reading.notes,
          );
        },
      ),
    );
  }
}
