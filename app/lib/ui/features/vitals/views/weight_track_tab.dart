import 'package:app/domain/models/weight_reading_options.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/widgets/numeric_stepper_input.dart';
import 'package:app/ui/features/vitals/widgets/vital_recorded_at_picker.dart';
import 'package:app/ui/features/vitals/widgets/vital_save_confirmation.dart';
import 'package:app/ui/features/vitals/widgets/vital_track_actions.dart';
import 'package:app/ui/features/vitals/widgets/weight_dialysis_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _defaultWeightKg = 70.0;

class WeightTrackTab extends StatefulWidget {
  const WeightTrackTab({super.key});

  @override
  State<WeightTrackTab> createState() => _WeightTrackTabState();
}

class _WeightTrackTabState extends State<WeightTrackTab> {
  double _draftValueKg = _defaultWeightKg;
  DateTime _draftRecordedAt = DateTime.now();
  String _dialysisTiming = dialysisTimingNonDialysis;
  String? _weightContext;
  bool _isSaving = false;
  bool _initialized = false;

  double _baselineValue(WeightViewModel viewModel) {
    return viewModel.latestReading?.valueKg ?? _defaultWeightKg;
  }

  DateTime _baselineRecordedAt() => DateTime.now();

  void _syncDraftFromViewModel(WeightViewModel viewModel) {
    _draftValueKg = _baselineValue(viewModel);
    _draftRecordedAt = _baselineRecordedAt();
    _dialysisTiming = dialysisTimingNonDialysis;
    _weightContext = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _syncDraftFromViewModel(context.read<WeightViewModel>());
    _initialized = true;
  }

  Future<void> _save(WeightViewModel viewModel) async {
    setState(() => _isSaving = true);
    try {
      await viewModel.addReading(
        valueKg: _draftValueKg,
        recordedAt: _draftRecordedAt,
        dialysisTiming: _dialysisTiming,
        weightContext: _weightContext,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _syncDraftFromViewModel(viewModel);
      });
      showVitalSavedConfirmation(
        context,
        message: 'Weight saved',
        accentColor: AppTheme.logWeight,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _clear(WeightViewModel viewModel) {
    setState(() {
      _syncDraftFromViewModel(viewModel);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeightViewModel>();

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
                  NumericStepperInput(
                    label: 'Weight (kg)',
                    value: _draftValueKg,
                    step: 0.5,
                    min: 0.5,
                    max: 300,
                    decimals: 1,
                    accentColor: AppTheme.logWeight,
                    allowDirectInput: true,
                    onChanged: (value) => setState(() => _draftValueKg = value),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  WeightDialysisPicker(
                    dialysisTiming: _dialysisTiming,
                    weightContext: _weightContext,
                    accentColor: AppTheme.logWeight,
                    onDialysisTimingChanged: (value) =>
                        setState(() => _dialysisTiming = value),
                    onWeightContextChanged: (value) =>
                        setState(() => _weightContext = value),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  VitalRecordedAtPicker(
                    recordedAt: _draftRecordedAt,
                    accentColor: AppTheme.logWeight,
                    onChanged: (value) =>
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
            saveColor: AppTheme.logWeight,
          ),
        ],
      ),
    );
  }
}
