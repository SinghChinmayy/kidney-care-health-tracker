import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/core/widgets/app_form_layout.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeightView extends StatelessWidget {
  const WeightView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeightViewModel>();

    return Scaffold(
      appBar: const AppScreenAppBar(title: 'Weight'),
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
    WeightViewModel viewModel,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: AppTheme.sheetTopRadius,
      ),
      builder: (sheetContext) {
        return _AddWeightForm(
          onSubmit: (valueKg, notes) {
            viewModel.addReading(valueKg: valueKg, notes: notes);
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }
}

class _AddWeightForm extends StatefulWidget {
  const _AddWeightForm({required this.onSubmit});

  final void Function(double valueKg, String? notes) onSubmit;

  @override
  State<_AddWeightForm> createState() => _AddWeightFormState();
}

class _AddWeightFormState extends State<_AddWeightForm> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingSm,
        right: AppTheme.spacingSm,
        top: AppTheme.spacingSm,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Log weight',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Values are stored in kg.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          TextFormField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
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
      ),
    );
  }

  void _submit() {
    final value = double.tryParse(_valueController.text.trim());
    if (value == null || value <= 0) {
      setState(() => _errorText = 'Enter a valid weight.');
      return;
    }
    setState(() => _errorText = null);
    widget.onSubmit(value, _notesController.text);
  }
}
