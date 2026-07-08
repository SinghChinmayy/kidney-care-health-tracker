import 'package:app/domain/models/weight_reading_options.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/widgets/weight_dialysis_picker.dart';
import 'package:flutter/material.dart';

const bloodGlucoseContextOptions = [
  'fasting',
  'post_meal',
  'random',
  'bedtime',
];

class AddBloodPressureForm extends StatefulWidget {
  const AddBloodPressureForm({super.key, required this.onSubmit});

  final void Function(
    int? systolic,
    int? diastolic,
    int? heartRate,
    String? notes,
  ) onSubmit;

  @override
  State<AddBloodPressureForm> createState() => _AddBloodPressureFormState();
}

class _AddBloodPressureFormState extends State<AddBloodPressureForm> {
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

class AddBloodGlucoseForm extends StatefulWidget {
  const AddBloodGlucoseForm({
    super.key,
    required this.contextOptions,
    required this.onSubmit,
  });

  final List<String> contextOptions;
  final void Function(double value, String? context, String? notes) onSubmit;

  @override
  State<AddBloodGlucoseForm> createState() => _AddBloodGlucoseFormState();
}

class _AddBloodGlucoseFormState extends State<AddBloodGlucoseForm> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedContext;
  String? _errorText;

  @override
  void dispose() {
    _valueController.dispose();
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
          'Log blood glucose',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          'Values are stored in mg/dL.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextFormField(
          controller: _valueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Glucose (mg/dL)'),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        DropdownButtonFormField<String>(
          initialValue: _selectedContext,
          decoration: const InputDecoration(labelText: 'Context (optional)'),
          items: widget.contextOptions
              .map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text(option.replaceAll('_', ' ')),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedContext = value),
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
    final value = double.tryParse(_valueController.text.trim());
    if (value == null || value <= 0) {
      setState(() => _errorText = 'Enter a valid glucose value.');
      return;
    }
    setState(() => _errorText = null);
    widget.onSubmit(value, _selectedContext, _notesController.text);
  }
}

class AddWeightForm extends StatefulWidget {
  const AddWeightForm({
    super.key,
    required this.onSubmit,
  });

  final void Function(
    double valueKg,
    String dialysisTiming,
    String? weightContext,
    String? notes,
  ) onSubmit;

  @override
  State<AddWeightForm> createState() => _AddWeightFormState();
}

class _AddWeightFormState extends State<AddWeightForm> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  String _dialysisTiming = dialysisTimingNonDialysis;
  String? _weightContext;
  String? _errorText;

  @override
  void dispose() {
    _valueController.dispose();
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
        WeightDialysisPicker(
          dialysisTiming: _dialysisTiming,
          weightContext: _weightContext,
          accentColor: AppTheme.logWeight,
          onDialysisTimingChanged: (value) =>
              setState(() => _dialysisTiming = value),
          onWeightContextChanged: (value) =>
              setState(() => _weightContext = value),
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
    final value = double.tryParse(_valueController.text.trim());
    if (value == null || value <= 0) {
      setState(() => _errorText = 'Enter a valid weight.');
      return;
    }
    setState(() => _errorText = null);
    widget.onSubmit(
      value,
      _dialysisTiming,
      _weightContext,
      _notesController.text,
    );
  }
}
