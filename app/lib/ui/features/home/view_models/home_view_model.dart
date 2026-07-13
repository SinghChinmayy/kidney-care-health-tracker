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

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required AuthRepository authRepository,
    required PatientRepository patientRepository,
    required VitalsRepository vitalsRepository,
  })  : _authRepository = authRepository,
        _patientRepository = patientRepository,
        _vitalsRepository = vitalsRepository,
        _selectedDate = localDateOnly(DateTime.now()) {
    refresh();
  }

  static const int checkInTotal = 2;

  final AuthRepository _authRepository;
  final PatientRepository _patientRepository;
  final VitalsRepository _vitalsRepository;

  DateTime _selectedDate;
  Patient? _patient;
  PatientPreferences? _preferences;
  List<BloodPressureReading> _bloodPressureReadings = [];
  List<BloodGlucoseReading> _bloodGlucoseReadings = [];
  List<WeightReading> _weightReadings = [];
  List<FluidIntakeLog> _fluidIntakeLogs = [];

  DateTime get selectedDate => _selectedDate;

  String get selectedDateLabel => formatHomeDateLabel(_selectedDate);

  DateTime get today => localDateOnly(DateTime.now());

  /// Monday of the week that contains [selectedDate].
  DateTime get visibleWeekStart {
    return _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
  }

  List<DateTime> get visibleWeekDays {
    final start = visibleWeekStart;
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  bool get canSelectNextWeek {
    final nextWeekStart = visibleWeekStart.add(const Duration(days: 7));
    return !nextWeekStart.isAfter(today);
  }

  String? get patientFirstName {
    final name = _patient?.firstName?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  String get greetingName => patientFirstName ?? 'there';

  String get patientInitials {
    final first = _patient?.firstName?.trim();
    final last = _patient?.lastName?.trim();
    final firstInitial =
        (first != null && first.isNotEmpty) ? first[0].toUpperCase() : '';
    final lastInitial =
        (last != null && last.isNotEmpty) ? last[0].toUpperCase() : '';
    final initials = '$firstInitial$lastInitial';
    if (initials.isNotEmpty) return initials;
    return '?';
  }

  List<int> get dialysisDaysOfWeek =>
      _patient?.dialysisDaysOfWeek ?? const [];

  bool isDialysisDay(DateTime date) {
    final days = _patient?.dialysisDaysOfWeek;
    if (days == null || days.isEmpty) return false;
    return days.contains(date.weekday);
  }

  bool get isSelectedDateDialysisDay => isDialysisDay(_selectedDate);

  int get dailyWaterGoalMl =>
      _preferences?.dailyWaterGoalMl ??
      PatientPreferences.defaultDailyWaterGoalMl;

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

  /// Daily latest glucose values for the 7 local days ending on selected date.
  List<BloodGlucoseHomeChartPoint> get bloodGlucoseChartForSelectedDate {
    final end = _selectedDate;
    final start = end.subtract(const Duration(days: 6));
    final latestByDay = <DateTime, BloodGlucoseReading>{};

    for (final reading in _bloodGlucoseReadings) {
      final day = localDateOnly(reading.recordedAt);
      if (day.isBefore(start) || day.isAfter(end)) {
        continue;
      }
      final existing = latestByDay[day];
      if (existing == null ||
          reading.recordedAt.isAfter(existing.recordedAt)) {
        latestByDay[day] = reading;
      }
    }

    final points = <BloodGlucoseHomeChartPoint>[];
    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final reading = latestByDay[day];
      if (reading != null) {
        points.add(
          BloodGlucoseHomeChartPoint(
            day: day,
            valueMgDl: reading.valueMgDl,
          ),
        );
      }
    }
    return points;
  }

  /// Interdialytic weight state as of the selected date (carry-forward).
  WeightGainSnapshot get weightGainForSelectedDate =>
      weightGainSnapshotOnLocalDate(_weightReadings, _selectedDate);

  WeightGainChartData get weightGainChartForSelectedDate =>
      weightGainChartOnLocalDate(_weightReadings, _selectedDate);

  String? get weightGainForSelectedDateLabel =>
      weightGainForSelectedDate.displayGain;

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

  String get fluidIntakeProgressLabel {
    final current = fluidIntakeTotalMlForSelectedDate.toStringAsFixed(0);
    return '$current / $dailyWaterGoalMl ml';
  }

  /// Ring fill 0..1 (clamped). Over-goal still reads as full ring.
  double get fluidIntakeProgress {
    final goal = dailyWaterGoalMl;
    if (goal <= 0) return 0;
    return (fluidIntakeTotalMlForSelectedDate / goal).clamp(0.0, 1.0);
  }

  bool get isFluidOverGoal =>
      fluidIntakeTotalMlForSelectedDate > dailyWaterGoalMl;

  int get checkInCompletedCount {
    var count = 0;
    if (bloodPressureForSelectedDate != null) count++;
    if (fluidIntakeTotalMlForSelectedDate > 0) count++;
    return count;
  }

  DateTime get logRecordedAt => recordedAtFromSelectedDate(_selectedDate);

  void selectDate(DateTime date) {
    final next = localDateOnly(date);
    final clamped = next.isAfter(today) ? today : next;
    if (clamped == _selectedDate) return;
    _selectedDate = clamped;
    notifyListeners();
  }

  void selectPreviousDay() {
    selectDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  void selectNextDay() {
    selectDate(_selectedDate.add(const Duration(days: 1)));
  }

  void selectPreviousWeek() {
    _shiftWeek(-7);
  }

  void selectNextWeek() {
    if (!canSelectNextWeek) return;
    _shiftWeek(7);
  }

  void _shiftWeek(int dayDelta) {
    final candidate = _selectedDate.add(Duration(days: dayDelta));
    if (candidate.isAfter(today)) {
      selectDate(today);
      return;
    }
    selectDate(candidate);
  }

  /// Move selection into [weekStart]'s week, keeping weekday when possible.
  void selectWeekStarting(DateTime weekStart) {
    final start = localDateOnly(weekStart);
    final weekdayOffset = _selectedDate.weekday - 1;
    var candidate = start.add(Duration(days: weekdayOffset));
    if (candidate.isAfter(today)) {
      candidate = today;
    }
    // If today is before this week entirely, clamp to week start if allowed.
    if (candidate.isBefore(start)) {
      candidate = start;
    }
    selectDate(candidate);
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
}
