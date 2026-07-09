import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/fluid_intake_view_model.dart';
import 'package:app/ui/features/vitals/widgets/date_grouped_history_list.dart';
import 'package:app/ui/features/vitals/widgets/weight_history_row.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FluidIntakeHistoryTab extends StatelessWidget {
  const FluidIntakeHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FluidIntakeViewModel>();

    return WeightHistoryListContainer(
      child: DateGroupedHistoryList(
        readings: viewModel.logs,
        recordedAt: (log) => log.recordedAt,
        emptyMessage: 'No water logged yet.\nSwitch to Track to add some.',
        accentColor: AppTheme.logFluidIntake,
        rowBuilder: (context, log) {
          return VitalHistoryRow(
            primaryText: log.displayValue,
            secondaryText: formatHistoryTime(log.recordedAt),
            notes: log.notes,
          );
        },
      ),
    );
  }
}
