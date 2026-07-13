import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/ui/features/vitals/models/blood_pressure_period.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BloodPressureViewModel extends ChangeNotifier {
  BloodPressureViewModel({required VitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository,
        _selectedWeekStart = bloodPressureWeekStart(DateTime.now()),
        _selectedMonthStart = bloodPressureMonthStart(DateTime.now()),
        _selectedYearStart = bloodPressureYearStart(DateTime.now()) {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  List<BloodPressureReading> _readings = [];
  BloodPressurePeriod _selectedPeriod = BloodPressurePeriod.week;
  DateTime _selectedWeekStart;
  DateTime _selectedMonthStart;
  DateTime _selectedYearStart;

  List<BloodPressureReading> get readings => _readings;

  BloodPressurePeriod get selectedPeriod => _selectedPeriod;

  DateTime get selectedWeekStart => _selectedWeekStart;

  DateTime get selectedMonthStart => _selectedMonthStart;

  DateTime get selectedYearStart => _selectedYearStart;

  String get selectedPeriodLabel => bloodPressurePeriodLabel(
        _selectedPeriod,
        weekStart: _selectedWeekStart,
        monthStart: _selectedMonthStart,
        yearStart: _selectedYearStart,
      );

  bool get showsPeriodNavigator =>
      _selectedPeriod == BloodPressurePeriod.week ||
      _selectedPeriod == BloodPressurePeriod.month ||
      _selectedPeriod == BloodPressurePeriod.year;

  bool get canSelectPreviousPeriod => showsPeriodNavigator;

  bool get canSelectNextPeriod {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case BloodPressurePeriod.week:
        return _selectedWeekStart.isBefore(bloodPressureWeekStart(now));
      case BloodPressurePeriod.month:
        final thisMonth = bloodPressureMonthStart(now);
        return _selectedMonthStart.year < thisMonth.year ||
            (_selectedMonthStart.year == thisMonth.year &&
                _selectedMonthStart.month < thisMonth.month);
      case BloodPressurePeriod.year:
        return _selectedYearStart.year < bloodPressureYearStart(now).year;
      case BloodPressurePeriod.all:
        return false;
    }
  }

  String get previousPeriodTooltip => switch (_selectedPeriod) {
        BloodPressurePeriod.week => 'Previous week',
        BloodPressurePeriod.month => 'Previous month',
        BloodPressurePeriod.year => 'Previous year',
        BloodPressurePeriod.all => 'Previous',
      };

  String get nextPeriodTooltip => switch (_selectedPeriod) {
        BloodPressurePeriod.week => 'Next week',
        BloodPressurePeriod.month => 'Next month',
        BloodPressurePeriod.year => 'Next year',
        BloodPressurePeriod.all => 'Next',
      };

  BloodPressureReading? get latestReading =>
      _readings.isEmpty ? null : _readings.first;

  ({DateTime start, DateTime end}) get _range {
    final earliest =
        _readings.isEmpty ? null : _readings.last.recordedAt; // oldest
    return bloodPressurePeriodRange(
      _selectedPeriod,
      DateTime.now(),
      earliestReadingAt: earliest,
      weekStart: _selectedWeekStart,
      monthStart: _selectedMonthStart,
      yearStart: _selectedYearStart,
    );
  }

  List<BloodPressureReading> get periodReadings {
    final range = _range;
    return bloodPressureReadingsInRange(_readings, range.start, range.end);
  }

  /// Newest reading in the selected period, else overall latest.
  BloodPressureReading? get heroReading {
    final inPeriod = periodReadings;
    if (inPeriod.isNotEmpty) {
      return inPeriod.first;
    }
    return latestReading;
  }

  String? get heroDisplayValue {
    final reading = heroReading;
    if (reading == null) {
      return null;
    }
    if (reading.systolic != null && reading.diastolic != null) {
      return '${reading.systolic}/${reading.diastolic}';
    }
    if (reading.heartRateBpm != null) {
      return '${reading.heartRateBpm}';
    }
    return null;
  }

  String get heroUnit {
    final reading = heroReading;
    if (reading == null) {
      return 'mmHg';
    }
    if (reading.systolic != null && reading.diastolic != null) {
      return 'mmHg';
    }
    if (reading.heartRateBpm != null) {
      return 'bpm';
    }
    return 'mmHg';
  }

  int get periodReadingCount => periodReadings.length;

  List<BloodPressureReading> get _periodWithSystolic => [
        for (final reading in periodReadings)
          if (reading.systolic != null) reading,
      ];

  /// Newest minus oldest systolic in the period. Null if < 2 systolic readings.
  int? get periodChangeSystolic {
    final withSys = _periodWithSystolic;
    if (withSys.length < 2) {
      return null;
    }
    return withSys.first.systolic! - withSys.last.systolic!;
  }

  double? get periodAverageSystolic {
    final withSys = _periodWithSystolic;
    if (withSys.isEmpty) {
      return null;
    }
    var sum = 0;
    for (final reading in withSys) {
      sum += reading.systolic!;
    }
    return sum / withSys.length;
  }

  List<BloodPressureChartDay> get chartDays {
    final range = _range;
    if (_selectedPeriod == BloodPressurePeriod.year) {
      return bloodPressureChartMonths(
        readings: _readings,
        start: range.start,
        end: range.end,
      );
    }
    return bloodPressureChartDays(
      readings: _readings,
      start: range.start,
      end: range.end,
    );
  }

  void selectPeriod(BloodPressurePeriod period) {
    if (period == _selectedPeriod) {
      return;
    }
    _selectedPeriod = period;
    final now = DateTime.now();
    switch (period) {
      case BloodPressurePeriod.week:
        _selectedWeekStart = bloodPressureWeekStart(now);
      case BloodPressurePeriod.month:
        _selectedMonthStart = bloodPressureMonthStart(now);
      case BloodPressurePeriod.year:
        _selectedYearStart = bloodPressureYearStart(now);
      case BloodPressurePeriod.all:
        break;
    }
    notifyListeners();
  }

  void selectPreviousPeriod() {
    if (!canSelectPreviousPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case BloodPressurePeriod.week:
        final start = bloodPressureLocalDateOnly(_selectedWeekStart);
        _selectedWeekStart = DateTime(start.year, start.month, start.day - 7);
      case BloodPressurePeriod.month:
        final start = bloodPressureMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month - 1, 1);
      case BloodPressurePeriod.year:
        final start = bloodPressureYearStart(_selectedYearStart);
        _selectedYearStart = DateTime(start.year - 1, 1, 1);
      case BloodPressurePeriod.all:
        return;
    }
    notifyListeners();
  }

  void selectNextPeriod() {
    if (!canSelectNextPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case BloodPressurePeriod.week:
        final start = bloodPressureLocalDateOnly(_selectedWeekStart);
        _selectedWeekStart = DateTime(start.year, start.month, start.day + 7);
      case BloodPressurePeriod.month:
        final start = bloodPressureMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month + 1, 1);
      case BloodPressurePeriod.year:
        final start = bloodPressureYearStart(_selectedYearStart);
        _selectedYearStart = DateTime(start.year + 1, 1, 1);
      case BloodPressurePeriod.all:
        return;
    }
    notifyListeners();
  }

  /// Systolic delta vs the next-older reading that has systolic. Null if none.
  int? changeVsPrevious(BloodPressureReading reading) {
    if (reading.systolic == null) {
      return null;
    }
    final index = _readings.indexWhere((r) => r.id == reading.id);
    if (index < 0) {
      return null;
    }
    for (var i = index + 1; i < _readings.length; i++) {
      final older = _readings[i];
      if (older.systolic != null) {
        return reading.systolic! - older.systolic!;
      }
    }
    return null;
  }

  Future<void> refresh() async {
    _readings = await _vitalsRepository.getBloodPressureReadings();
    notifyListeners();
  }

  Future<void> addReading({
    int? systolic,
    int? diastolic,
    int? heartRateBpm,
    String? notes,
    DateTime? recordedAt,
  }) async {
    final hasBp = systolic != null && diastolic != null;
    final hasHr = heartRateBpm != null;
    if (!hasBp && !hasHr) {
      return;
    }

    final reading = BloodPressureReading(
      id: const Uuid().v4(),
      recordedAt: (recordedAt ?? DateTime.now()).toUtc(),
      systolic: systolic,
      diastolic: diastolic,
      heartRateBpm: heartRateBpm,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    await _vitalsRepository.addBloodPressureReading(reading);
    await refresh();
  }

  Future<void> updateReading({
    required BloodPressureReading existing,
    int? systolic,
    int? diastolic,
    int? heartRateBpm,
    required DateTime recordedAt,
    String? notes,
  }) async {
    final hasBp = systolic != null && diastolic != null;
    final hasHr = heartRateBpm != null;
    if (!hasBp && !hasHr) {
      return;
    }

    await _vitalsRepository.updateBloodPressureReading(
      BloodPressureReading(
        id: existing.id,
        patientId: existing.patientId,
        recordedAt: recordedAt.toUtc(),
        systolic: systolic,
        diastolic: diastolic,
        heartRateBpm: heartRateBpm,
        notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
        deletedAt: existing.deletedAt,
      ),
    );
    await refresh();
  }

  Future<void> deleteReading(String id) async {
    await _vitalsRepository.deleteBloodPressureReading(id);
    await refresh();
  }
}
