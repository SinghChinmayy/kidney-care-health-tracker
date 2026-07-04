import 'package:app/data/repositories/mock_vitals_repository.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:flutter/material.dart';

class WeightViewModel extends ChangeNotifier {
  WeightViewModel({required MockVitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository {
    _load();
  }

  final MockVitalsRepository _vitalsRepository;
  List<WeightReading> _readings = [];

  List<WeightReading> get readings => _readings;

  void _load() {
    _readings = _vitalsRepository.getWeightReadings();
  }

  void refresh() {
    _load();
    notifyListeners();
  }

  void addReading({required double valueKg, String? notes}) {
    final reading = WeightReading(
      id: 'wt-${DateTime.now().millisecondsSinceEpoch}',
      recordedAt: DateTime.now(),
      valueKg: valueKg,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    _vitalsRepository.addWeightReading(reading);
    refresh();
  }
}
