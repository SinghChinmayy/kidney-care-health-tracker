import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required VitalsRepository vitalsRepository,
    required AuthRepository authRepository,
  })  : _vitalsRepository = vitalsRepository,
        _authRepository = authRepository {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  final AuthRepository _authRepository;

  BloodPressureReading? _latestBloodPressure;
  BloodGlucoseReading? _latestBloodGlucose;
  WeightReading? _latestWeight;

  BloodPressureReading? get latestBloodPressure => _latestBloodPressure;
  BloodGlucoseReading? get latestBloodGlucose => _latestBloodGlucose;
  WeightReading? get latestWeight => _latestWeight;

  Future<void> signOut() {
    return _authRepository.signOut();
  }

  Future<void> refresh() async {
    _latestBloodPressure = await _vitalsRepository.getLatestBloodPressure();
    _latestBloodGlucose = await _vitalsRepository.getLatestBloodGlucose();
    _latestWeight = await _vitalsRepository.getLatestWeight();
    notifyListeners();
  }
}
