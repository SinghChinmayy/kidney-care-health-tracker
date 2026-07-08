import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_reading_form.dart';
import 'package:app/ui/features/vitals/widgets/vital_save_confirmation.dart';
import 'package:app/ui/features/vitals/widgets/vital_track_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _defaultGlucoseMgDl = 100.0;

class BloodGlucoseTrackTab extends StatefulWidget {
  const BloodGlucoseTrackTab({super.key});

  @override
  State<BloodGlucoseTrackTab> createState() => _BloodGlucoseTrackTabState();
}

class _BloodGlucoseTrackTabState extends State<BloodGlucoseTrackTab> {
  double _draftValueMgDl = _defaultGlucoseMgDl;
  String? _selectedContext;
  DateTime _draftRecordedAt = DateTime.now();
  bool _isSaving = false;
  bool _initialized = false;

  void _syncDraftFromViewModel(BloodGlucoseViewModel viewModel) {
    final latest = viewModel.readings.isEmpty ? null : viewModel.readings.first;
    _draftValueMgDl = latest?.valueMgDl ?? _defaultGlucoseMgDl;
    _selectedContext = latest?.context;
    _draftRecordedAt = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _syncDraftFromViewModel(context.read<BloodGlucoseViewModel>());
    _initialized = true;
  }

  Future<void> _save(BloodGlucoseViewModel viewModel) async {
    setState(() => _isSaving = true);
    try {
      await viewModel.addReading(
        valueMgDl: _draftValueMgDl,
        context: _selectedContext,
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
        message: 'Blood glucose saved',
        accentColor: AppTheme.logBloodGlucose,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _clear(BloodGlucoseViewModel viewModel) {
    setState(() {
      _syncDraftFromViewModel(viewModel);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BloodGlucoseViewModel>();

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
                  BloodGlucoseReadingForm(
                    valueMgDl: _draftValueMgDl,
                    selectedContext: _selectedContext,
                    recordedAt: _draftRecordedAt,
                    onValueChanged: (value) =>
                        setState(() => _draftValueMgDl = value),
                    onContextChanged: (value) =>
                        setState(() => _selectedContext = value),
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
            saveColor: AppTheme.logBloodGlucose,
          ),
        ],
      ),
    );
  }
}
