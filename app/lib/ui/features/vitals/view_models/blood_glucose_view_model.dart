import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BloodGlucoseViewModel extends ChangeNotifier {
  BloodGlucoseViewModel({required VitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  List<BloodGlucoseReading> _readings = [];

  List<BloodGlucoseReading> get readings => _readings;

  Future<void> refresh() async {
    _readings = await _vitalsRepository.getBloodGlucoseReadings();
    notifyListeners();
  }

  Future<void> addReading({
    required double valueMgDl,
    String? context,
    String? notes,
    DateTime? recordedAt,
  }) async {
    final reading = BloodGlucoseReading(
      id: const Uuid().v4(),
      recordedAt: (recordedAt ?? DateTime.now()).toUtc(),
      valueMgDl: valueMgDl,
      context: context?.trim().isEmpty ?? true ? null : context?.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    await _vitalsRepository.addBloodGlucoseReading(reading);
    await refresh();
  }
}
