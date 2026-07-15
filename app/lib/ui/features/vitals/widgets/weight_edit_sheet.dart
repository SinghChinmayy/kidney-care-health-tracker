import 'package:app/domain/models/weight_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/widgets/vital_save_confirmation.dart';
import 'package:app/ui/features/vitals/widgets/weight_reading_form.dart';
import 'package:flutter/material.dart';

Future<bool> confirmDeleteWeightReading(BuildContext context) async {
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

Future<void> showWeightEditSheet(
  BuildContext context, {
  required WeightReading reading,
  required WeightViewModel viewModel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return _WeightEditSheet(
        reading: reading,
        viewModel: viewModel,
        parentContext: context,
      );
    },
  );
}

class _WeightEditSheet extends StatefulWidget {
  const _WeightEditSheet({
    required this.reading,
    required this.viewModel,
    required this.parentContext,
  });

  final WeightReading reading;
  final WeightViewModel viewModel;
  final BuildContext parentContext;

  @override
  State<_WeightEditSheet> createState() => _WeightEditSheetState();
}

class _WeightEditSheetState extends State<_WeightEditSheet> {
  late double _valueKg;
  late String _dialysisTiming;
  late String? _weightContext;
  late DateTime _recordedAt;
  late final TextEditingController _notesController;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isBusy => _isSaving || _isDeleting;

  @override
  void initState() {
    super.initState();
    final reading = widget.reading;
    _valueKg = reading.valueKg;
    _dialysisTiming = reading.dialysisTiming;
    _weightContext = reading.weightContext;
    _recordedAt = reading.recordedAt.toLocal();
    _notesController = TextEditingController(text: reading.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.viewModel.updateReading(
        existing: widget.reading,
        valueKg: _valueKg,
        dialysisTiming: _dialysisTiming,
        recordedAt: _recordedAt,
        weightContext: _weightContext,
        notes: _notesController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      if (widget.parentContext.mounted) {
        showVitalSavedConfirmation(
          widget.parentContext,
          message: 'Weight updated',
          accentColor: AppTheme.logWeight,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmDeleteWeightReading(context);
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
          message: 'Weight deleted',
          accentColor: AppTheme.logWeight,
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
              'Edit weight',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            WeightReadingForm(
              valueKg: _valueKg,
              dialysisTiming: _dialysisTiming,
              weightContext: _weightContext,
              recordedAt: _recordedAt,
              notesController: _notesController,
              onValueKgChanged: (value) => setState(() => _valueKg = value),
              onDialysisTimingChanged: (value) =>
                  setState(() => _dialysisTiming = value),
              onWeightContextChanged: (value) =>
                  setState(() => _weightContext = value),
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

Future<void> confirmAndDeleteWeightReading(
  BuildContext context, {
  required WeightReading reading,
  required WeightViewModel viewModel,
}) async {
  final confirmed = await confirmDeleteWeightReading(context);
  if (!confirmed || !context.mounted) {
    return;
  }

  await viewModel.deleteReading(reading.id);
  if (!context.mounted) {
    return;
  }
  showVitalSavedConfirmation(
    context,
    message: 'Weight deleted',
    accentColor: AppTheme.logWeight,
  );
}
