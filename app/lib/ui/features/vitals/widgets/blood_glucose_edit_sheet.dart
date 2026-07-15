import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_reading_form.dart';
import 'package:app/ui/features/vitals/widgets/vital_save_confirmation.dart';
import 'package:flutter/material.dart';

Future<bool> confirmDeleteBloodGlucoseReading(BuildContext context) async {
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

Future<void> showBloodGlucoseEditSheet(
  BuildContext context, {
  required BloodGlucoseReading reading,
  required BloodGlucoseViewModel viewModel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return _BloodGlucoseEditSheet(
        reading: reading,
        viewModel: viewModel,
        parentContext: context,
      );
    },
  );
}

class _BloodGlucoseEditSheet extends StatefulWidget {
  const _BloodGlucoseEditSheet({
    required this.reading,
    required this.viewModel,
    required this.parentContext,
  });

  final BloodGlucoseReading reading;
  final BloodGlucoseViewModel viewModel;
  final BuildContext parentContext;

  @override
  State<_BloodGlucoseEditSheet> createState() => _BloodGlucoseEditSheetState();
}

class _BloodGlucoseEditSheetState extends State<_BloodGlucoseEditSheet> {
  late double _valueMgDl;
  late String? _selectedContext;
  late DateTime _recordedAt;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isBusy => _isSaving || _isDeleting;

  @override
  void initState() {
    super.initState();
    final reading = widget.reading;
    _valueMgDl = reading.valueMgDl;
    _selectedContext = reading.context;
    _recordedAt = reading.recordedAt.toLocal();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.viewModel.updateReading(
        existing: widget.reading,
        valueMgDl: _valueMgDl,
        context: _selectedContext,
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
          message: 'Glucose updated',
          accentColor: AppTheme.logBloodGlucose,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmDeleteBloodGlucoseReading(context);
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
          message: 'Glucose deleted',
          accentColor: AppTheme.logBloodGlucose,
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
              'Edit blood glucose',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            BloodGlucoseReadingForm(
              valueMgDl: _valueMgDl,
              selectedContext: _selectedContext,
              recordedAt: _recordedAt,
              onValueChanged: (value) => setState(() => _valueMgDl = value),
              onContextChanged: (value) =>
                  setState(() => _selectedContext = value),
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
                        color: AppTheme.cardSurface,
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
