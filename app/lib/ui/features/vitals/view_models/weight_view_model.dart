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
  bool _isOnDialysis = false;

  List<WeightReading> get readings => _readings;

  bool get isOnDialysis => _isOnDialysis;

  WeightReading? get latestReading =>
      _readings.isEmpty ? null : _readings.first;

  Future<void> refresh() async {
    final patient = await _vitalsRepository.getCurrentPatient();
    _isOnDialysis = patient != null && patient.dialysisType != 'none';
    _readings = await _vitalsRepository.getWeightReadings();
    notifyListeners();
  }

  Future<void> addReading({
    required double valueKg,
    required String dialysisTiming,
    DateTime? recordedAt,
    String? weightContext,
    String? notes,
  }) async {
    final reading = WeightReading(
      id: const Uuid().v4(),
      recordedAt: (recordedAt ?? DateTime.now()).toUtc(),
      valueKg: valueKg,
      dialysisTiming: dialysisTiming,
      weightContext: weightContext?.trim().isEmpty ?? true
          ? null
          : weightContext?.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    await _vitalsRepository.addWeightReading(reading);
    await refresh();
  }

  Future<void> updateReading({
    required WeightReading existing,
    required double valueKg,
    required String dialysisTiming,
    required DateTime recordedAt,
    String? weightContext,
    String? notes,
  }) async {
    await _vitalsRepository.updateWeightReading(
      WeightReading(
        id: existing.id,
        patientId: existing.patientId,
        recordedAt: recordedAt.toUtc(),
        valueKg: valueKg,
        dialysisTiming: dialysisTiming,
        weightContext: weightContext?.trim().isEmpty ?? true
            ? null
            : weightContext?.trim(),
        source: existing.source,
        notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
        deletedAt: existing.deletedAt,
      ),
    );
    await refresh();
  }

  Future<void> deleteReading(String id) async {
    await _vitalsRepository.deleteWeightReading(id);
    await refresh();
  }
}
