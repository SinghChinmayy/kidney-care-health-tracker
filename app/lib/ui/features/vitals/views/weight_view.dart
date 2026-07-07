import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/core/widgets/app_form_layout.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_sheets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeightView extends StatefulWidget {
  const WeightView({super.key});

  @override
  State<WeightView> createState() => _WeightViewState();
}

class _WeightViewState extends State<WeightView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WeightViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeightViewModel>();

    return Scaffold(
      appBar: const AppScreenAppBar(title: 'Weight'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showWeightLogSheet(
          context,
          onSaved: viewModel.refresh,
        ),
        child: const Icon(Icons.add),
      ),
      body: viewModel.readings.isEmpty
          ? const AppEmptyState(message: 'No readings yet.\nTap + to log one.')
          : ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              itemCount: viewModel.readings.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppTheme.spacingSm),
              itemBuilder: (context, index) {
                final reading = viewModel.readings[index];
                return AppReadingCard(
                  value: reading.displayValue,
                  recordedAt: formatRecordedAt(reading.recordedAt),
                  notes: reading.notes,
                );
              },
            ),
    );
  }
}
