import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/core/widgets/app_form_layout.dart';
import 'package:app/ui/features/vitals/view_models/blood_pressure_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BloodPressureView extends StatefulWidget {
  const BloodPressureView({super.key});

  @override
  State<BloodPressureView> createState() => _BloodPressureViewState();
}

class _BloodPressureViewState extends State<BloodPressureView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BloodPressureViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BloodPressureViewModel>();

    return Scaffold(
      appBar: const AppScreenAppBar(title: 'Blood pressure'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, viewModel),
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

  Future<void> _showAddSheet(
    BuildContext context,
    BloodPressureViewModel viewModel,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: AppTheme.sheetTopRadius,
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppTheme.spacingSm,
            right: AppTheme.spacingSm,
            top: AppTheme.spacingSm,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                AppTheme.spacingSm,
          ),
          child: _AddBloodPressureForm(
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
            },
          ),
        );
      },
    );
  }
}

class _AddBloodPressureForm extends StatefulWidget {
  const _AddBloodPressureForm({required this.onSubmit});

  final void Function(
    int? systolic,
    int? diastolic,
    int? heartRate,
    String? notes,
  ) onSubmit;

  @override
  State<_AddBloodPressureForm> createState() => _AddBloodPressureFormState();
}

class _AddBloodPressureFormState extends State<_AddBloodPressureForm> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _notesController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Log blood pressure',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          'Enter BP and/or heart rate. At least one is required.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextFormField(
          controller: _systolicController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Systolic (mmHg)'),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextFormField(
          controller: _diastolicController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Diastolic (mmHg)'),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextFormField(
          controller: _heartRateController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Heart rate (bpm)'),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
          maxLines: 2,
        ),
        if (_errorText != null) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Text(_errorText!, style: TextStyle(color: AppTheme.error)),
        ],
        const SizedBox(height: AppTheme.spacingMd),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save reading'),
        ),
      ],
    );
  }

  void _submit() {
    final systolic = _parseInt(_systolicController.text);
    final diastolic = _parseInt(_diastolicController.text);
    final heartRate = _parseInt(_heartRateController.text);
    final hasBp = systolic != null && diastolic != null;
    final hasPartialBp =
        (systolic != null && diastolic == null) ||
        (systolic == null && diastolic != null);
    final hasHr = heartRate != null;

    if (hasPartialBp) {
      setState(() {
        _errorText = 'Enter both systolic and diastolic, or leave both empty.';
      });
      return;
    }
    if (!hasBp && !hasHr) {
      setState(() {
        _errorText = 'Enter blood pressure and/or heart rate.';
      });
      return;
    }

    setState(() => _errorText = null);
    widget.onSubmit(
      systolic,
      diastolic,
      heartRate,
      _notesController.text,
    );
  }

  int? _parseInt(String value) {
    if (value.trim().isEmpty) {
      return null;
    }
    return int.tryParse(value.trim());
  }
}
