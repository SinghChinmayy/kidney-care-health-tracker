import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/patient_preferences.dart';
import 'package:app/domain/models/weight_gain_from_dry_weight.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';

class BloodGlucoseHomeChartPoint {
  const BloodGlucoseHomeChartPoint({
    required this.day,
    required this.valueMgDl,
  });

  final DateTime day;
  final double valueMgDl;
}

class BloodPressureHomeChartPoint {
  const BloodPressureHomeChartPoint({
    required this.day,
    required this.systolic,
    this.diastolic,
  });

  final DateTime day;
  final int systolic;
  final int? diastolic;
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this._authRepository,
    required this._patientRepository,
    required this._vitalsRepository,
  }) {
    final now = localDateOnly(DateTime.now());
    _selectedDate = now;
    _visibleWeekStart = weekStartForLocalDate(now);
    refresh();
  }

  final AuthRepository _authRepository;
  final PatientRepository _patientRepository;
  final VitalsRepository _vitalsRepository;

  late DateTime _selectedDate;
  /// Monday of the week shown in the home calendar. May differ from
  /// [selectedDate] when browsing future weeks.
  late DateTime _visibleWeekStart;
  Patient? _patient;
  PatientPreferences? _preferences;
  List<BloodPressureReading> _bloodPressureReadings = [];
  List<BloodGlucoseReading> _bloodGlucoseReadings = [];
  List<WeightReading> _weightReadings = [];
  List<FluidIntakeLog> _fluidIntakeLogs = [];

  DateTime get selectedDate => _selectedDate;

  DateTime get today => localDateOnly(DateTime.now());

  /// Monday of the week currently shown on the home calendar.
  DateTime get visibleWeekStart => _visibleWeekStart;

  String get greetingName {
    final name = _patient?.firstName?.trim();
    if (name == null || name.isEmpty) return 'there';
    return name;
  }

  String get patientInitials {
    final first = _patient?.firstName?.trim();
    final last = _patient?.lastName?.trim();
    final firstInitial =
        (first != null && first.isNotEmpty) ? first[0].toUpperCase() : '';
    final lastInitial =
        (last != null && last.isNotEmpty) ? last[0].toUpperCase() : '';
    final initials = '$firstInitial$lastInitial';
    return initials.isNotEmpty ? initials : '?';
  }

  int get dailyWaterGoalMl =>
      _preferences?.dailyWaterGoalMl ??
      PatientPreferences.defaultDailyWaterGoalMl;

  /// Daily latest glucose for the 7 local days ending on selected date.
  List<BloodGlucoseHomeChartPoint> get bloodGlucoseChartForSelectedDate {
    return _dailyLatestChart(
      readings: _bloodGlucoseReadings,
      recordedAt: (r) => r.recordedAt,
      mapPoint: (day, r) => BloodGlucoseHomeChartPoint(
        day: day,
        valueMgDl: r.valueMgDl,
      ),
    );
  }

  /// Daily latest systolic for the 7 local days ending on selected date.
  List<BloodPressureHomeChartPoint> get bloodPressureChartForSelectedDate {
    return _dailyLatestChart(
      readings: _bloodPressureReadings.where((r) => r.systolic != null),
      recordedAt: (r) => r.recordedAt,
      mapPoint: (day, r) => BloodPressureHomeChartPoint(
        day: day,
        systolic: r.systolic!,
        diastolic: r.diastolic,
      ),
    );
  }

  WeightGainSnapshot get weightGainForSelectedDate =>
      weightGainSnapshotOnLocalDate(_weightReadings, _selectedDate);

  double get fluidIntakeTotalMlForSelectedDate {
    var total = 0.0;
    for (final log in _fluidIntakeLogs) {
      if (localDateOnly(log.recordedAt) == _selectedDate) {
        total += log.fluidMl;
      }
    }
    return total;
  }

  /// Ring fill 0..1 (clamped). Over-goal still reads as full ring.
  double get fluidIntakeProgress {
    final goal = dailyWaterGoalMl;
    if (goal <= 0) return 0;
    return (fluidIntakeTotalMlForSelectedDate / goal).clamp(0.0, 1.0);
  }

  bool get isFluidOverGoal =>
      fluidIntakeTotalMlForSelectedDate > dailyWaterGoalMl;

  DateTime get logRecordedAt => recordedAtFromSelectedDate(_selectedDate);

  void selectDate(DateTime date) {
    final next = localDateOnly(date);
    final clamped = next.isAfter(today) ? today : next;
    final weekStart = weekStartForLocalDate(clamped);
    if (clamped == _selectedDate && weekStart == _visibleWeekStart) return;
    _selectedDate = clamped;
    _visibleWeekStart = weekStart;
    notifyListeners();
  }

  /// Show [weekStart]'s Mon–Sun week. Keeps weekday when that day is selectable;
  /// future-only weeks update the visible week without changing selection.
  void selectWeekStarting(DateTime weekStart) {
    final start = weekStartForLocalDate(weekStart);
    if (start == _visibleWeekStart) return;

    _visibleWeekStart = start;

    if (start.isAfter(today)) {
      notifyListeners();
      return;
    }

    final weekEnd = start.add(const Duration(days: 6));
    var candidate = start.add(Duration(days: _selectedDate.weekday - 1));
    if (candidate.isAfter(today)) {
      candidate = today;
    }
    if (candidate.isBefore(start)) {
      candidate = start;
    }
    if (candidate.isAfter(weekEnd)) {
      candidate = weekEnd.isAfter(today) ? today : weekEnd;
    }

    _selectedDate = candidate;
    notifyListeners();
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? today : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null) {
      selectDate(picked);
    }
  }

  Future<void> refresh() async {
    final authUserId = _authRepository.currentSession?.user.id;

    final vitalsFuture = Future.wait([
      _vitalsRepository.getBloodPressureReadings(),
      _vitalsRepository.getBloodGlucoseReadings(),
      _vitalsRepository.getWeightReadings(),
      _vitalsRepository.getFluidIntakeLogs(),
    ]);

    final Future<List<Object?>>? profileFuture = authUserId == null
        ? null
        : Future.wait([
            _patientRepository.getPatientForAuthUser(authUserId),
            _patientRepository.getOrCreatePreferencesForAuthUser(authUserId),
          ]);

    final vitalsResults = await vitalsFuture;
    _bloodPressureReadings = vitalsResults[0] as List<BloodPressureReading>;
    _bloodGlucoseReadings = vitalsResults[1] as List<BloodGlucoseReading>;
    _weightReadings = vitalsResults[2] as List<WeightReading>;
    _fluidIntakeLogs = vitalsResults[3] as List<FluidIntakeLog>;

    if (profileFuture == null) {
      _patient = null;
      _preferences = null;
    } else {
      final profileResults = await profileFuture;
      _patient = profileResults[0] as Patient?;
      _preferences = profileResults[1] as PatientPreferences?;
    }

    notifyListeners();
  }

  List<TPoint> _dailyLatestChart<TReading, TPoint>({
    required Iterable<TReading> readings,
    required DateTime Function(TReading reading) recordedAt,
    required TPoint Function(DateTime day, TReading reading) mapPoint,
  }) {
    final end = _selectedDate;
    final start = end.subtract(const Duration(days: 6));
    final latestByDay = <DateTime, TReading>{};

    for (final reading in readings) {
      final day = localDateOnly(recordedAt(reading));
      if (day.isBefore(start) || day.isAfter(end)) continue;
      final existing = latestByDay[day];
      if (existing == null ||
          recordedAt(reading).isAfter(recordedAt(existing))) {
        latestByDay[day] = reading;
      }
    }

    final points = <TPoint>[];
    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final reading = latestByDay[day];
      if (reading != null) {
        points.add(mapPoint(day, reading));
      }
    }
    return points;
  }
}
