import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required VitalsRepository vitalsRepository,
    required AuthRepository authRepository,
  })  : _vitalsRepository = vitalsRepository,
        _authRepository = authRepository,
        _selectedDate = localDateOnly(DateTime.now()) {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  final AuthRepository _authRepository;

  DateTime _selectedDate;
  List<BloodPressureReading> _bloodPressureReadings = [];
  List<BloodGlucoseReading> _bloodGlucoseReadings = [];
  List<WeightReading> _weightReadings = [];

  DateTime get selectedDate => _selectedDate;

  String get selectedDateLabel => formatHomeDateLabel(_selectedDate);

  BloodPressureReading? get bloodPressureForSelectedDate =>
      latestReadingOnLocalDate(
        _bloodPressureReadings,
        _selectedDate,
        (reading) => reading.recordedAt,
      );

  BloodGlucoseReading? get bloodGlucoseForSelectedDate =>
      latestReadingOnLocalDate(
        _bloodGlucoseReadings,
        _selectedDate,
        (reading) => reading.recordedAt,
      );

  WeightReading? get weightForSelectedDate => latestReadingOnLocalDate(
        _weightReadings,
        _selectedDate,
        (reading) => reading.recordedAt,
      );

  DateTime get logRecordedAt => recordedAtFromSelectedDate(_selectedDate);

  void selectDate(DateTime date) {
    _selectedDate = localDateOnly(date);
    notifyListeners();
  }

  void selectPreviousDay() {
    selectDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  void selectNextDay() {
    selectDate(_selectedDate.add(const Duration(days: 1)));
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      selectDate(picked);
    }
  }

  Future<void> signOut() {
    return _authRepository.signOut();
  }

  Future<void> refresh() async {
    final results = await Future.wait([
      _vitalsRepository.getBloodPressureReadings(),
      _vitalsRepository.getBloodGlucoseReadings(),
      _vitalsRepository.getWeightReadings(),
    ]);
    _bloodPressureReadings = results[0] as List<BloodPressureReading>;
    _bloodGlucoseReadings = results[1] as List<BloodGlucoseReading>;
    _weightReadings = results[2] as List<WeightReading>;
    notifyListeners();
  }
}
