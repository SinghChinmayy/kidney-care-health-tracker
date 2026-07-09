import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:app/domain/models/weight_gain_from_dry_weight.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required VitalsRepository vitalsRepository,
  })  : _vitalsRepository = vitalsRepository,
        _selectedDate = localDateOnly(DateTime.now()) {
    refresh();
  }

  final VitalsRepository _vitalsRepository;

  DateTime _selectedDate;
  List<BloodPressureReading> _bloodPressureReadings = [];
  List<BloodGlucoseReading> _bloodGlucoseReadings = [];
  List<WeightReading> _weightReadings = [];
  List<FluidIntakeLog> _fluidIntakeLogs = [];

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

  /// Gain since last post-dialysis weight vs latest non-dialysis / random
  /// entry on the selected date.
  WeightGainFromDryWeight? get weightGainForSelectedDate =>
      weightGainFromDryWeightOnLocalDate(_weightReadings, _selectedDate);

  String? get weightGainForSelectedDateLabel =>
      weightGainForSelectedDate?.displayGain;

  double get fluidIntakeTotalMlForSelectedDate {
    var total = 0.0;
    for (final log in _fluidIntakeLogs) {
      final local = log.recordedAt.toLocal();
      final logDay = DateTime(local.year, local.month, local.day);
      if (logDay == _selectedDate) {
        total += log.fluidMl;
      }
    }
    return total;
  }

  String? get fluidIntakeForSelectedDateLabel {
    final total = fluidIntakeTotalMlForSelectedDate;
    if (total <= 0) {
      return null;
    }
    return '${total.toStringAsFixed(0)} ml';
  }

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

  Future<void> refresh() async {
    final results = await Future.wait([
      _vitalsRepository.getBloodPressureReadings(),
      _vitalsRepository.getBloodGlucoseReadings(),
      _vitalsRepository.getWeightReadings(),
      _vitalsRepository.getFluidIntakeLogs(),
    ]);
    _bloodPressureReadings = results[0] as List<BloodPressureReading>;
    _bloodGlucoseReadings = results[1] as List<BloodGlucoseReading>;
    _weightReadings = results[2] as List<WeightReading>;
    _fluidIntakeLogs = results[3] as List<FluidIntakeLog>;
    notifyListeners();
  }
}
