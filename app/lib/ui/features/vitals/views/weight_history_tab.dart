import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/widgets/date_grouped_history_list.dart';
import 'package:app/ui/features/vitals/widgets/weight_edit_sheet.dart';
import 'package:app/ui/features/vitals/widgets/weight_history_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeightHistoryTab extends StatelessWidget {
  const WeightHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeightViewModel>();

    return WeightHistoryListContainer(
      child: DateGroupedHistoryList(
        readings: viewModel.readings,
        recordedAt: (reading) => reading.recordedAt,
        emptyMessage: 'No readings yet.\nSwitch to Track to log one.',
        accentColor: AppTheme.logWeight,
        rowBuilder: (context, reading) {
          return WeightHistoryRow(
            reading: reading,
            onTap: () => showWeightEditSheet(
              context,
              reading: reading,
              viewModel: viewModel,
            ),
          );
        },
      ),
    );
  }
}
