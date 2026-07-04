import 'package:app/data/repositories/mock_vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:flutter/material.dart';

class BloodGlucoseViewModel extends ChangeNotifier {
  BloodGlucoseViewModel({required MockVitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository {
    _load();
  }

  final MockVitalsRepository _vitalsRepository;
  List<BloodGlucoseReading> _readings = [];

  List<BloodGlucoseReading> get readings => _readings;

  void _load() {
    _readings = _vitalsRepository.getBloodGlucoseReadings();
  }

  void refresh() {
    _load();
    notifyListeners();
  }

  void addReading({
    required double valueMgDl,
    String? context,
    String? notes,
  }) {
    final reading = BloodGlucoseReading(
      id: 'bg-${DateTime.now().millisecondsSinceEpoch}',
      recordedAt: DateTime.now(),
      valueMgDl: valueMgDl,
      context: context?.trim().isEmpty ?? true ? null : context?.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    _vitalsRepository.addBloodGlucoseReading(reading);
    refresh();
  }
}
