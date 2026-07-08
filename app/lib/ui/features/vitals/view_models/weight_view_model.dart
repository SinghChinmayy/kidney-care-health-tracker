import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class WeightViewModel extends ChangeNotifier {
  WeightViewModel({required VitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  List<WeightReading> _readings = [];

  List<WeightReading> get readings => _readings;

  WeightReading? get latestReading =>
      _readings.isEmpty ? null : _readings.first;

  Future<void> refresh() async {
    _readings = await _vitalsRepository.getWeightReadings();
    notifyListeners();
  }

  Future<void> addReading({
    required double valueKg,
    DateTime? recordedAt,
    String? notes,
  }) async {
    final reading = WeightReading(
      id: const Uuid().v4(),
      recordedAt: (recordedAt ?? DateTime.now()).toUtc(),
      valueKg: valueKg,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    await _vitalsRepository.addWeightReading(reading);
    await refresh();
  }
}
