import 'package:app/data/repositories/mock_vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required MockVitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository {
    _refresh();
  }

  final MockVitalsRepository _vitalsRepository;

  BloodPressureReading? _latestBloodPressure;
  BloodGlucoseReading? _latestBloodGlucose;
  WeightReading? _latestWeight;

  BloodPressureReading? get latestBloodPressure => _latestBloodPressure;
  BloodGlucoseReading? get latestBloodGlucose => _latestBloodGlucose;
  WeightReading? get latestWeight => _latestWeight;

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
