import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/weight_reading.dart';

class MockVitalsRepository {
  MockVitalsRepository() {
    _bloodPressure = _seedBloodPressure();
    _bloodGlucose = _seedBloodGlucose();
    _weight = _seedWeight();
  }

  late List<BloodPressureReading> _bloodPressure;
  late List<BloodGlucoseReading> _bloodGlucose;
  late List<WeightReading> _weight;

  List<BloodPressureReading> getBloodPressureReadings() =>
      List.unmodifiable(_bloodPressure);

  List<BloodGlucoseReading> getBloodGlucoseReadings() =>
      List.unmodifiable(_bloodGlucose);

  List<WeightReading> getWeightReadings() => List.unmodifiable(_weight);

  BloodPressureReading? getLatestBloodPressure() =>
      _bloodPressure.isEmpty ? null : _bloodPressure.first;

  BloodGlucoseReading? getLatestBloodGlucose() =>
      _bloodGlucose.isEmpty ? null : _bloodGlucose.first;

  WeightReading? getLatestWeight() => _weight.isEmpty ? null : _weight.first;

  void addBloodPressureReading(BloodPressureReading reading) {
    _bloodPressure = [reading, ..._bloodPressure];
  }

  void addBloodGlucoseReading(BloodGlucoseReading reading) {
    _bloodGlucose = [reading, ..._bloodGlucose];
  }

  void addWeightReading(WeightReading reading) {
    _weight = [reading, ..._weight];
  }

  List<BloodPressureReading> _seedBloodPressure() {
    final now = DateTime.now();
    return [
      BloodPressureReading(
        id: 'bp-1',
        recordedAt: now.subtract(const Duration(hours: 2)),
        systolic: 128,
        diastolic: 82,
        heartRateBpm: 72,
      ),
      BloodPressureReading(
        id: 'bp-2',
        recordedAt: now.subtract(const Duration(days: 1)),
        systolic: 132,
        diastolic: 86,
        heartRateBpm: 68,
        notes: 'After morning meds',
      ),
    ];
  }

  List<BloodGlucoseReading> _seedBloodGlucose() {
    final now = DateTime.now();
    return [
      BloodGlucoseReading(
        id: 'bg-1',
        recordedAt: now.subtract(const Duration(hours: 5)),
        valueMgDl: 118,
        context: 'fasting',
      ),
      BloodGlucoseReading(
        id: 'bg-2',
        recordedAt: now.subtract(const Duration(days: 1)),
        valueMgDl: 142,
        context: 'post_meal',
      ),
    ];
  }

  List<WeightReading> _seedWeight() {
    final now = DateTime.now();
    return [
      WeightReading(
        id: 'wt-1',
        recordedAt: now.subtract(const Duration(hours: 8)),
        valueKg: 72.4,
      ),
      WeightReading(
        id: 'wt-2',
        recordedAt: now.subtract(const Duration(days: 2)),
        valueKg: 72.8,
      ),
    ];
  }
}
