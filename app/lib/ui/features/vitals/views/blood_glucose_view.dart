import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/core/widgets/app_form_layout.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_sheets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BloodGlucoseView extends StatefulWidget {
  const BloodGlucoseView({super.key});

  @override
  State<BloodGlucoseView> createState() => _BloodGlucoseViewState();
}

class _BloodGlucoseViewState extends State<BloodGlucoseView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BloodGlucoseViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BloodGlucoseViewModel>();

    return Scaffold(
      appBar: const AppScreenAppBar(title: 'Blood glucose'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBloodGlucoseLogSheet(
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
                  subtitle: reading.context?.replaceAll('_', ' '),
                  notes: reading.notes,
                );
              },
            ),
    );
  }
}
