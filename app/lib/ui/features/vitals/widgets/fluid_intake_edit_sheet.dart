import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/fluid_intake_view_model.dart';
import 'package:app/ui/features/vitals/widgets/fluid_intake_reading_form.dart';
import 'package:app/ui/features/vitals/widgets/vital_save_confirmation.dart';
import 'package:flutter/material.dart';

Future<bool> confirmDeleteFluidIntakeLog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete log?'),
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

Future<void> showFluidIntakeEditSheet(
  BuildContext context, {
  required FluidIntakeLog log,
  required FluidIntakeViewModel viewModel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return _FluidIntakeEditSheet(
        log: log,
        viewModel: viewModel,
        parentContext: context,
      );
    },
  );
}

class _FluidIntakeEditSheet extends StatefulWidget {
  const _FluidIntakeEditSheet({
    required this.log,
    required this.viewModel,
    required this.parentContext,
  });

  final FluidIntakeLog log;
  final FluidIntakeViewModel viewModel;
  final BuildContext parentContext;

  @override
  State<_FluidIntakeEditSheet> createState() => _FluidIntakeEditSheetState();
}

class _FluidIntakeEditSheetState extends State<_FluidIntakeEditSheet> {
  late double _fluidMl;
  late DateTime _recordedAt;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isBusy => _isSaving || _isDeleting;

  @override
  void initState() {
    super.initState();
    final log = widget.log;
    _fluidMl = log.fluidMl;
    _recordedAt = log.recordedAt.toLocal();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.viewModel.updateLog(
        existing: widget.log,
        fluidMl: _fluidMl,
        recordedAt: _recordedAt,
        notes: widget.log.notes,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      if (widget.parentContext.mounted) {
        showVitalSavedConfirmation(
          widget.parentContext,
          message: 'Water intake updated',
          accentColor: AppTheme.logFluidIntake,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmDeleteFluidIntakeLog(context);
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await widget.viewModel.deleteLog(widget.log.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      if (widget.parentContext.mounted) {
        showVitalSavedConfirmation(
          widget.parentContext,
          message: 'Water intake deleted',
          accentColor: AppTheme.logFluidIntake,
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
              'Edit water intake',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            FluidIntakeReadingForm(
              fluidMl: _fluidMl,
              recordedAt: _recordedAt,
              onFluidMlChanged: (value) => setState(() => _fluidMl = value),
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
                  : const Text('Delete log'),
            ),
          ],
        ),
      ),
    );
  }
}
