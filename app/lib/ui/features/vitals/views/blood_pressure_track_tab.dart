import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/blood_pressure_view_model.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_log_type_picker.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_reading_form.dart';
import 'package:app/ui/features/vitals/widgets/vital_save_confirmation.dart';
import 'package:app/ui/features/vitals/widgets/vital_track_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _defaultSystolic = 120;
const _defaultDiastolic = 80;
const _defaultHeartRate = 72;

class BloodPressureTrackTab extends StatefulWidget {
  const BloodPressureTrackTab({super.key});

  @override
  State<BloodPressureTrackTab> createState() => _BloodPressureTrackTabState();
}

class _BloodPressureTrackTabState extends State<BloodPressureTrackTab> {
  BloodPressureLogType _logType = BloodPressureLogType.bloodPressure;
  int _draftSystolic = _defaultSystolic;
  int _draftDiastolic = _defaultDiastolic;
  int _draftHeartRate = _defaultHeartRate;
  DateTime _draftRecordedAt = DateTime.now();
  bool _isSaving = false;
  bool _initialized = false;

  BloodPressureLogType _baselineLogType(BloodPressureReading? latest) {
    if (latest == null) {
      return BloodPressureLogType.bloodPressure;
    }
    final hasBp = latest.systolic != null && latest.diastolic != null;
    final hasHr = latest.heartRateBpm != null;
    if (hasBp && hasHr) {
      return BloodPressureLogType.both;
    }
    if (hasHr) {
      return BloodPressureLogType.heartRate;
    }
    return BloodPressureLogType.bloodPressure;
  }

  void _syncDraftFromViewModel(BloodPressureViewModel viewModel) {
    final latest = viewModel.readings.isEmpty ? null : viewModel.readings.first;
    _logType = _baselineLogType(latest);
    _draftSystolic = latest?.systolic ?? _defaultSystolic;
    _draftDiastolic = latest?.diastolic ?? _defaultDiastolic;
    _draftHeartRate = latest?.heartRateBpm ?? _defaultHeartRate;
    _draftRecordedAt = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _syncDraftFromViewModel(context.read<BloodPressureViewModel>());
    _initialized = true;
  }

  Future<void> _save(BloodPressureViewModel viewModel) async {
    final systolic = _logType == BloodPressureLogType.heartRate
        ? null
        : _draftSystolic;
    final diastolic = _logType == BloodPressureLogType.heartRate
        ? null
        : _draftDiastolic;
    final heartRate = _logType == BloodPressureLogType.bloodPressure
        ? null
        : _draftHeartRate;

    setState(() => _isSaving = true);
    try {
      await viewModel.addReading(
        systolic: systolic,
        diastolic: diastolic,
        heartRateBpm: heartRate,
        recordedAt: _draftRecordedAt,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _syncDraftFromViewModel(viewModel);
      });
      showVitalSavedConfirmation(
        context,
        message: 'Blood pressure saved',
        accentColor: AppTheme.logBloodPressure,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _clear(BloodPressureViewModel viewModel) {
    setState(() {
      _syncDraftFromViewModel(viewModel);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BloodPressureViewModel>();

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppTheme.spacingMd),
                  BloodPressureReadingForm(
                    logType: _logType,
                    systolic: _draftSystolic,
                    diastolic: _draftDiastolic,
                    heartRateBpm: _draftHeartRate,
                    recordedAt: _draftRecordedAt,
                    onLogTypeChanged: (value) =>
                        setState(() => _logType = value),
                    onSystolicChanged: (value) =>
                        setState(() => _draftSystolic = value),
                    onDiastolicChanged: (value) =>
                        setState(() => _draftDiastolic = value),
                    onHeartRateChanged: (value) =>
                        setState(() => _draftHeartRate = value),
                    onRecordedAtChanged: (value) =>
                        setState(() => _draftRecordedAt = value),
                  ),
                ],
              ),
            ),
          ),
          VitalTrackActions(
            onSave: () => _save(viewModel),
            onClear: () => _clear(viewModel),
            isSaving: _isSaving,
            saveColor: AppTheme.logBloodPressure,
          ),
        ],
      ),
    );
  }
}
