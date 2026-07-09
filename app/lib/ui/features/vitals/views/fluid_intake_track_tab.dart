import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/fluid_intake_view_model.dart';
import 'package:app/ui/features/vitals/widgets/fluid_intake_reading_form.dart';
import 'package:app/ui/features/vitals/widgets/vital_save_confirmation.dart';
import 'package:app/ui/features/vitals/widgets/vital_track_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _defaultFluidMl = 250.0;

class FluidIntakeTrackTab extends StatefulWidget {
  const FluidIntakeTrackTab({super.key});

  @override
  State<FluidIntakeTrackTab> createState() => _FluidIntakeTrackTabState();
}

class _FluidIntakeTrackTabState extends State<FluidIntakeTrackTab> {
  double _draftFluidMl = _defaultFluidMl;
  DateTime _draftRecordedAt = DateTime.now();
  bool _isSaving = false;
  bool _initialized = false;

  void _syncDraftFromViewModel(FluidIntakeViewModel viewModel) {
    final latest = viewModel.logs.isEmpty ? null : viewModel.logs.first;
    _draftFluidMl = latest?.fluidMl ?? _defaultFluidMl;
    _draftRecordedAt = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _syncDraftFromViewModel(context.read<FluidIntakeViewModel>());
    _initialized = true;
  }

  Future<void> _save(FluidIntakeViewModel viewModel) async {
    setState(() => _isSaving = true);
    try {
      await viewModel.addLog(
        fluidMl: _draftFluidMl,
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
        message: 'Water intake saved',
        accentColor: AppTheme.logFluidIntake,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _clear(FluidIntakeViewModel viewModel) {
    setState(() {
      _syncDraftFromViewModel(viewModel);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FluidIntakeViewModel>();
    final todayTotal = viewModel.totalMlOnLocalDate(DateTime.now());

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
                  Text(
                    'Today: ${todayTotal.toStringAsFixed(0)} ml',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  FluidIntakeReadingForm(
                    fluidMl: _draftFluidMl,
                    recordedAt: _draftRecordedAt,
                    onFluidMlChanged: (value) =>
                        setState(() => _draftFluidMl = value),
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
            saveColor: AppTheme.logFluidIntake,
          ),
        ],
      ),
    );
  }
}
