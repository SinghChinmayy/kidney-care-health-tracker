import 'package:app/data/repositories/mock_vitals_repository.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:flutter/material.dart';

class BloodPressureViewModel extends ChangeNotifier {
  BloodPressureViewModel({required MockVitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository {
    _load();
  }

  final MockVitalsRepository _vitalsRepository;
  List<BloodPressureReading> _readings = [];

  List<BloodPressureReading> get readings => _readings;

  void _load() {
    _readings = _vitalsRepository.getBloodPressureReadings();
  }

  void refresh() {
    _load();
    notifyListeners();
  }

  void addReading({
    int? systolic,
    int? diastolic,
    int? heartRateBpm,
    String? notes,
  }) {
    final hasBp = systolic != null && diastolic != null;
    final hasHr = heartRateBpm != null;
    if (!hasBp && !hasHr) {
      return;
    }

    final reading = BloodPressureReading(
      id: 'bp-${DateTime.now().millisecondsSinceEpoch}',
      recordedAt: DateTime.now(),
      systolic: systolic,
      diastolic: diastolic,
      heartRateBpm: heartRateBpm,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    _vitalsRepository.addBloodPressureReading(reading);
    refresh();
  }
}
