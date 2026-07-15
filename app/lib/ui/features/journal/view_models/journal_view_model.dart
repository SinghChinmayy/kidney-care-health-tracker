import 'package:app/data/repositories/medications_repository.dart';
import 'package:app/data/repositories/patient_medication_schedule_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/medication.dart';
import 'package:app/domain/models/patient_medication_schedule.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/domain/models/weight_reading_options.dart';
import 'package:flutter/foundation.dart';

class JournalViewModel extends ChangeNotifier {
  JournalViewModel({
    required VitalsRepository vitalsRepository,
    required MedicationsRepository medicationsRepository,
    required PatientMedicationScheduleRepository scheduleRepository,
  })  : _vitalsRepository = vitalsRepository,
        _medicationsRepository = medicationsRepository,
        _scheduleRepository = scheduleRepository {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  final MedicationsRepository _medicationsRepository;
  final PatientMedicationScheduleRepository _scheduleRepository;

  WeightReading? _dryWeight;
  List<Medication> _medications = [];
  PatientMedicationSchedule? _schedule;
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

  Map<String, Medication> get medicationById => {
        for (final med in _medications) med.id: med,
      };

  int get medicationCount => _medications.length;

  PatientMedicationSchedule? get schedule => _schedule;

  bool get isLoading => _isLoading;

  String? get error => _error;

  List<Medication> medsForDaySorted(int isoWeekday) {
    final ids = _schedule?.medIdsForDay(isoWeekday) ?? const [];
    final meds = <Medication>[];
    for (final id in ids) {
      final med = medicationById[id];
      if (med != null) {
        meds.add(med);
      }
    }
    meds.sort(
      (a, b) => a.pharmaceuticalName
          .toLowerCase()
          .compareTo(b.pharmaceuticalName.toLowerCase()),
    );
    return meds;
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final weights = await _vitalsRepository.getWeightReadings();
      _dryWeight = _latestPostDialysis(weights);
      _medications = await _medicationsRepository.getAll();
      _schedule = await _scheduleRepository.getOrCreateForCurrentPatient();
    } catch (_) {
      _error = 'Could not load journal data.';
      _dryWeight = null;
      _medications = [];
      _schedule = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyDialysisDaysChange(List<int> newDays) async {
    _schedule = await _scheduleRepository.applyDialysisDaysChange(
      newDays: newDays,
    );
    notifyListeners();
  }

  Future<bool> addMedToDay({
    required int isoWeekday,
    required String medicationId,
  }) async {
    final before = _schedule?.medIdsForDay(isoWeekday) ?? const [];
    if (before.contains(medicationId)) {
      return false;
    }
    _schedule = await _scheduleRepository.addMedToDay(
      isoWeekday: isoWeekday,
      medicationId: medicationId,
    );
    notifyListeners();
    return true;
  }

  Future<void> removeMedFromDay({
    required int isoWeekday,
    required String medicationId,
  }) async {
    _schedule = await _scheduleRepository.removeMedFromDay(
      isoWeekday: isoWeekday,
      medicationId: medicationId,
    );
    notifyListeners();
  }

  Future<bool> replaceMedOnDay({
    required int isoWeekday,
    required String oldMedicationId,
    required String newMedicationId,
  }) async {
    final ids = _schedule?.medIdsForDay(isoWeekday) ?? const [];
    if (newMedicationId != oldMedicationId && ids.contains(newMedicationId)) {
      return false;
    }
    _schedule = await _scheduleRepository.replaceMedOnDay(
      isoWeekday: isoWeekday,
      oldMedicationId: oldMedicationId,
      newMedicationId: newMedicationId,
    );
    notifyListeners();
    return true;
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

String dialysisDayOrdinalLabel(int index) {
  final n = index + 1;
  if (n == 1) {
    return 'First day of dialysis';
  }
  if (n == 2) {
    return '2nd day of dialysis';
  }
  if (n == 3) {
    return '3rd day of dialysis';
  }
  return '${n}th day of dialysis';
}

String weekdayFullLabel(int isoWeekday) {
  return switch (isoWeekday) {
    1 => 'Monday',
    2 => 'Tuesday',
    3 => 'Wednesday',
    4 => 'Thursday',
    5 => 'Friday',
    6 => 'Saturday',
    7 => 'Sunday',
    _ => 'Day $isoWeekday',
  };
}
