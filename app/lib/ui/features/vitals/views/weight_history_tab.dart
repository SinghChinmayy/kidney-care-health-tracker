import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/widgets/date_grouped_history_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeightHistoryTab extends StatelessWidget {
  const WeightHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeightViewModel>();

    return DateGroupedHistoryList(
      readings: viewModel.readings,
      recordedAt: (reading) => reading.recordedAt,
      emptyMessage: 'No readings yet.\nSwitch to Track to log one.',
      accentColor: AppTheme.logWeight,
      rowBuilder: (context, reading) {
        return VitalHistoryRow(
          primaryText: reading.displayValue,
          secondaryText: formatHistoryTime(reading.recordedAt),
          notes: reading.notes,
        );
      },
    );
  }
}
