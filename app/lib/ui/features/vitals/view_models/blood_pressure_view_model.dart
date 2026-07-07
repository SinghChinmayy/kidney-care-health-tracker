import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BloodPressureViewModel extends ChangeNotifier {
  BloodPressureViewModel({required VitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  List<BloodPressureReading> _readings = [];

  List<BloodPressureReading> get readings => _readings;

  Future<void> refresh() async {
    _readings = await _vitalsRepository.getBloodPressureReadings();
    notifyListeners();
  }

  Future<void> addReading({
    int? systolic,
    int? diastolic,
    int? heartRateBpm,
    String? notes,
  }) async {
    final hasBp = systolic != null && diastolic != null;
    final hasHr = heartRateBpm != null;
    if (!hasBp && !hasHr) {
      return;
    }

    final reading = BloodPressureReading(
      id: const Uuid().v4(),
      recordedAt: DateTime.now().toUtc(),
      systolic: systolic,
      diastolic: diastolic,
      heartRateBpm: heartRateBpm,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    await _vitalsRepository.addBloodPressureReading(reading);
    await refresh();
  }
}
