import 'dart:convert';
import 'dart:io';

import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/widgets/numeric_stepper_input.dart';
import 'package:app/ui/features/vitals/widgets/vital_recorded_at_picker.dart';
import 'package:app/ui/features/vitals/widgets/vital_track_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _defaultWeightKg = 70.0;
const _debugLogPath =
    '/Users/chinmay/workspace/projects/kidney-care/.cursor/debug-d53706.log';

class WeightTrackTab extends StatefulWidget {
  const WeightTrackTab({super.key});

  @override
  State<WeightTrackTab> createState() => _WeightTrackTabState();
}

class _WeightTrackTabState extends State<WeightTrackTab> {
  double _draftValueKg = _defaultWeightKg;
  DateTime _draftRecordedAt = DateTime.now();
  bool _isSaving = false;
  bool _initialized = false;

  // #region agent log
  void _debugLog(String message, Map<String, dynamic> data, String hypothesisId) {
    try {
      final payload = jsonEncode({
        'sessionId': 'd53706',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'location': 'weight_track_tab.dart',
        'message': message,
        'data': data,
        'hypothesisId': hypothesisId,
        'runId': 'post-fix',
      });
      File(_debugLogPath).writeAsStringSync('$payload\n', mode: FileMode.append);
    } catch (_) {}
  }
  // #endregion

  double _baselineValue(WeightViewModel viewModel) {
    return viewModel.latestReading?.valueKg ?? _defaultWeightKg;
  }

  DateTime _baselineRecordedAt() => DateTime.now();

  void _syncDraftFromViewModel(WeightViewModel viewModel) {
    _draftValueKg = _baselineValue(viewModel);
    _draftRecordedAt = _baselineRecordedAt();
  }

  @override
  void initState() {
    super.initState();
    // #region agent log
    _debugLog('initState defaults set', {
      'draftValueKg': _draftValueKg,
      'draftRecordedAt': _draftRecordedAt.toIso8601String(),
    }, 'H1');
    // #endregion
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _syncDraftFromViewModel(context.read<WeightViewModel>());
    _initialized = true;
    // #region agent log
    _debugLog('didChangeDependencies synced draft', {
      'draftValueKg': _draftValueKg,
      'draftRecordedAt': _draftRecordedAt.toIso8601String(),
    }, 'H2');
    // #endregion
  }

  Future<void> _save(WeightViewModel viewModel) async {
    setState(() => _isSaving = true);
    try {
      await viewModel.addReading(
        valueKg: _draftValueKg,
        recordedAt: _draftRecordedAt,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _draftValueKg = _baselineValue(viewModel);
        _draftRecordedAt = _baselineRecordedAt();
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _clear(WeightViewModel viewModel) {
    setState(() {
      _draftValueKg = _baselineValue(viewModel);
      _draftRecordedAt = _baselineRecordedAt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeightViewModel>();
    // #region agent log
    _debugLog('build using draft state', {
      'initialized': _initialized,
      'draftValueKg': _draftValueKg,
      'draftRecordedAt': _draftRecordedAt.toIso8601String(),
    }, 'H1');
    // #endregion

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
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
          VitalRecordedAtPicker(
            recordedAt: _draftRecordedAt,
            accentColor: AppTheme.logWeight,
            onChanged: (value) => setState(() => _draftRecordedAt = value),
          ),
          const Spacer(),
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
