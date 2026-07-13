import 'package:app/data/repositories/medications_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/medication.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/domain/models/weight_reading_options.dart';
import 'package:flutter/foundation.dart';

/// Aggregates dialysis-prep glance data for the Journal tab.
/// Dialysis type / days / fluid goal are edited via [ProfileViewModel]
/// (same underlying patient + preferences rows).
class JournalViewModel extends ChangeNotifier {
  JournalViewModel({
    required VitalsRepository vitalsRepository,
    required MedicationsRepository medicationsRepository,
  })  : _vitalsRepository = vitalsRepository,
        _medicationsRepository = medicationsRepository {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  final MedicationsRepository _medicationsRepository;

  WeightReading? _dryWeight;
  List<Medication> _medications = [];
  bool _isLoading = true;
  String? _error;

  WeightReading? get dryWeight => _dryWeight;

  String get dryWeightLabel {
    final reading = _dryWeight;
    if (reading == null) {
      return 'Not logged yet';
    }
    return '${reading.valueKg.toStringAsFixed(1)} kg';
  }

  String? get dryWeightMetaLabel {
    final reading = _dryWeight;
    if (reading == null) {
      return 'Log a post-dialysis weight to set dry weight';
    }
    final local = reading.recordedAt.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    return 'Latest post-dialysis · $date';
  }

  List<Medication> get medications => _medications;

  int get medicationCount => _medications.length;

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final weights = await _vitalsRepository.getWeightReadings();
      _dryWeight = _latestPostDialysis(weights);
      _medications = await _medicationsRepository.getAll();
    } catch (_) {
      _error = 'Could not load journal data.';
      _dryWeight = null;
      _medications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  WeightReading? _latestPostDialysis(List<WeightReading> readings) {
    for (final reading in readings) {
      if (reading.dialysisTiming == dialysisTimingPostDialysis &&
          reading.deletedAt == null) {
        return reading;
      }
    }
    return null;
  }
}
