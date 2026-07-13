import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/blood_pressure_view_model.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_log_type_picker.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_reading_form.dart';
import 'package:app/ui/features/vitals/widgets/vital_save_confirmation.dart';
import 'package:flutter/material.dart';

const _defaultSystolic = 120;
const _defaultDiastolic = 80;
const _defaultHeartRate = 72;

BloodPressureLogType bloodPressureLogTypeFor(BloodPressureReading reading) {
  final hasBp = reading.systolic != null && reading.diastolic != null;
  final hasHr = reading.heartRateBpm != null;
  if (hasBp && hasHr) {
    return BloodPressureLogType.both;
  }
  if (hasHr) {
    return BloodPressureLogType.heartRate;
  }
  return BloodPressureLogType.bloodPressure;
}

Future<bool> confirmDeleteBloodPressureReading(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete reading?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

Future<void> showBloodPressureEditSheet(
  BuildContext context, {
  required BloodPressureReading reading,
  required BloodPressureViewModel viewModel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.background,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return _BloodPressureEditSheet(
        reading: reading,
        viewModel: viewModel,
        parentContext: context,
      );
    },
  );
}

class _BloodPressureEditSheet extends StatefulWidget {
  const _BloodPressureEditSheet({
    required this.reading,
    required this.viewModel,
    required this.parentContext,
  });

  final BloodPressureReading reading;
  final BloodPressureViewModel viewModel;
  final BuildContext parentContext;

  @override
  State<_BloodPressureEditSheet> createState() =>
      _BloodPressureEditSheetState();
}

class _BloodPressureEditSheetState extends State<_BloodPressureEditSheet> {
  late BloodPressureLogType _logType;
  late int _systolic;
  late int _diastolic;
  late int _heartRateBpm;
  late DateTime _recordedAt;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isBusy => _isSaving || _isDeleting;

  @override
  void initState() {
    super.initState();
    final reading = widget.reading;
    _logType = bloodPressureLogTypeFor(reading);
    _systolic = reading.systolic ?? _defaultSystolic;
    _diastolic = reading.diastolic ?? _defaultDiastolic;
    _heartRateBpm = reading.heartRateBpm ?? _defaultHeartRate;
    _recordedAt = reading.recordedAt.toLocal();
  }

  Future<void> _save() async {
    final systolic =
        _logType == BloodPressureLogType.heartRate ? null : _systolic;
    final diastolic =
        _logType == BloodPressureLogType.heartRate ? null : _diastolic;
    final heartRate =
        _logType == BloodPressureLogType.bloodPressure ? null : _heartRateBpm;

    setState(() => _isSaving = true);
    try {
      await widget.viewModel.updateReading(
        existing: widget.reading,
        systolic: systolic,
        diastolic: diastolic,
        heartRateBpm: heartRate,
        recordedAt: _recordedAt,
        notes: widget.reading.notes,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      if (widget.parentContext.mounted) {
        showVitalSavedConfirmation(
          widget.parentContext,
          message: 'Blood pressure updated',
          accentColor: AppTheme.logBloodPressure,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmDeleteBloodPressureReading(context);
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await widget.viewModel.deleteReading(widget.reading.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      if (widget.parentContext.mounted) {
        showVitalSavedConfirmation(
          widget.parentContext,
          message: 'Blood pressure deleted',
          accentColor: AppTheme.logBloodPressure,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingSm,
        right: AppTheme.spacingSm,
        top: AppTheme.spacingSm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingSm,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit blood pressure',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            BloodPressureReadingForm(
              logType: _logType,
              systolic: _systolic,
              diastolic: _diastolic,
              heartRateBpm: _heartRateBpm,
              recordedAt: _recordedAt,
              onLogTypeChanged: (value) => setState(() => _logType = value),
              onSystolicChanged: (value) => setState(() => _systolic = value),
              onDiastolicChanged: (value) => setState(() => _diastolic = value),
              onHeartRateChanged: (value) =>
                  setState(() => _heartRateBpm = value),
              onRecordedAtChanged: (value) =>
                  setState(() => _recordedAt = value),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ElevatedButton(
              onPressed: _isBusy ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.background,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _isBusy ? null : _delete,
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: _isDeleting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.error,
                      ),
                    )
                  : const Text('Delete reading'),
            ),
          ],
        ),
      ),
    );
  }
}
