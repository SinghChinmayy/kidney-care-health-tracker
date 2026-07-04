import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/mock_vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required MockVitalsRepository vitalsRepository,
    required AuthRepository authRepository,
  })  : _vitalsRepository = vitalsRepository,
        _authRepository = authRepository {
    _refresh();
  }

  final MockVitalsRepository _vitalsRepository;
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

  void refresh() {
    _refresh();
    notifyListeners();
  }

  void _refresh() {
    _latestBloodPressure = _vitalsRepository.getLatestBloodPressure();
    _latestBloodGlucose = _vitalsRepository.getLatestBloodGlucose();
    _latestWeight = _vitalsRepository.getLatestWeight();
  }
}
