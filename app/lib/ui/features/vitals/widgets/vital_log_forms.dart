import 'package:app/domain/models/weight_reading_options.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_context_picker.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_log_type_picker.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_reading_form.dart';
import 'package:app/ui/features/vitals/widgets/fluid_intake_reading_form.dart';
import 'package:app/ui/features/vitals/widgets/vital_recorded_at_picker.dart';
import 'package:app/ui/features/vitals/widgets/weight_dialysis_picker.dart';
import 'package:flutter/material.dart';

const bloodGlucoseContextOptions = [
  'fasting',
  'post_meal',
  'random',
  'bedtime',
];

class AddBloodPressureForm extends StatefulWidget {
  const AddBloodPressureForm({
    super.key,
    required this.onSubmit,
    this.initialRecordedAt,
  });

  final DateTime? initialRecordedAt;
  final void Function(
    int? systolic,
    int? diastolic,
    int? heartRate,
    DateTime recordedAt,
  ) onSubmit;

  @override
  State<AddBloodPressureForm> createState() => _AddBloodPressureFormState();
}

class _AddBloodPressureFormState extends State<AddBloodPressureForm> {
  BloodPressureLogType _logType = BloodPressureLogType.bloodPressure;
  int _systolic = 120;
  int _diastolic = 80;
  int _heartRate = 72;
  late DateTime _recordedAt;

  @override
  void initState() {
    super.initState();
    _recordedAt = widget.initialRecordedAt ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Log blood pressure',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        BloodPressureReadingForm(
          logType: _logType,
          systolic: _systolic,
          diastolic: _diastolic,
          heartRateBpm: _heartRate,
          recordedAt: _recordedAt,
          onLogTypeChanged: (value) => setState(() => _logType = value),
          onSystolicChanged: (value) => setState(() => _systolic = value),
          onDiastolicChanged: (value) => setState(() => _diastolic = value),
          onHeartRateChanged: (value) => setState(() => _heartRate = value),
          onRecordedAtChanged: (value) => setState(() => _recordedAt = value),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        ElevatedButton(
          onPressed: _submit,
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  void _submit() {
    final systolic =
        _logType == BloodPressureLogType.heartRate ? null : _systolic;
    final diastolic =
        _logType == BloodPressureLogType.heartRate ? null : _diastolic;
    final heartRate =
        _logType == BloodPressureLogType.bloodPressure ? null : _heartRate;

    widget.onSubmit(systolic, diastolic, heartRate, _recordedAt);
  }
}

class AddBloodGlucoseForm extends StatefulWidget {
  const AddBloodGlucoseForm({
    super.key,
    required this.onSubmit,
    this.initialRecordedAt,
  });

  final DateTime? initialRecordedAt;
  final void Function(
    double value,
    String? context,
    DateTime recordedAt,
  ) onSubmit;

  @override
  State<AddBloodGlucoseForm> createState() => _AddBloodGlucoseFormState();
}

class _AddBloodGlucoseFormState extends State<AddBloodGlucoseForm> {
  final _valueController = TextEditingController(text: '100');
  String? _selectedContext;
  late DateTime _recordedAt;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _recordedAt = widget.initialRecordedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _valueController.dispose();
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          'Values are stored in mg/dL.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextFormField(
          controller: _valueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Glucose (mg/dL)'),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        BloodGlucoseContextPicker(
          selectedContext: _selectedContext,
          accentColor: AppTheme.logBloodGlucose,
          onChanged: (value) => setState(() => _selectedContext = value),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        VitalRecordedAtPicker(
          recordedAt: _recordedAt,
          accentColor: AppTheme.logBloodGlucose,
          compact: true,
          onChanged: (value) => setState(() => _recordedAt = value),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Text(_errorText!, style: TextStyle(color: AppTheme.error)),
        ],
        const SizedBox(height: AppTheme.spacingSm),
        ElevatedButton(
          onPressed: _submit,
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
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
    widget.onSubmit(value, _selectedContext, _recordedAt);
  }
}

class AddWeightForm extends StatefulWidget {
  const AddWeightForm({
    super.key,
    required this.onSubmit,
    this.initialRecordedAt,
  });

  final DateTime? initialRecordedAt;
  final void Function(
    double valueKg,
    String dialysisTiming,
    String? weightContext,
    String? notes,
    DateTime recordedAt,
  ) onSubmit;

  @override
  State<AddWeightForm> createState() => _AddWeightFormState();
}

class _AddWeightFormState extends State<AddWeightForm> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  String _dialysisTiming = dialysisTimingNonDialysis;
  String? _weightContext;
  late DateTime _recordedAt;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _recordedAt = widget.initialRecordedAt ?? DateTime.now();
  }

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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          'Values are stored in kg.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacingSm),
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
        VitalRecordedAtPicker(
          recordedAt: _recordedAt,
          accentColor: AppTheme.logWeight,
          compact: true,
          onChanged: (value) => setState(() => _recordedAt = value),
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
        const SizedBox(height: AppTheme.spacingSm),
        ElevatedButton(
          onPressed: _submit,
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
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
      _recordedAt,
    );
  }
}

class AddFluidIntakeForm extends StatefulWidget {
  const AddFluidIntakeForm({
    super.key,
    required this.onSubmit,
    this.initialRecordedAt,
  });

  final DateTime? initialRecordedAt;
  final void Function(
    double fluidMl,
    DateTime recordedAt,
  ) onSubmit;

  @override
  State<AddFluidIntakeForm> createState() => _AddFluidIntakeFormState();
}

class _AddFluidIntakeFormState extends State<AddFluidIntakeForm> {
  double _fluidMl = 250;
  late DateTime _recordedAt;

  @override
  void initState() {
    super.initState();
    _recordedAt = widget.initialRecordedAt ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Log water intake',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        FluidIntakeReadingForm(
          fluidMl: _fluidMl,
          recordedAt: _recordedAt,
          onFluidMlChanged: (value) => setState(() => _fluidMl = value),
          onRecordedAtChanged: (value) => setState(() => _recordedAt = value),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        ElevatedButton(
          onPressed: () => widget.onSubmit(_fluidMl, _recordedAt),
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
