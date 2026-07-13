import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/ui/features/vitals/models/blood_glucose_period.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BloodGlucoseViewModel extends ChangeNotifier {
  BloodGlucoseViewModel({required VitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository,
        _selectedWeekStart = bloodGlucoseWeekStart(DateTime.now()),
        _selectedMonthStart = bloodGlucoseMonthStart(DateTime.now()),
        _selectedYearStart = bloodGlucoseYearStart(DateTime.now()) {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  List<BloodGlucoseReading> _readings = [];
  BloodGlucosePeriod _selectedPeriod = BloodGlucosePeriod.week;
  DateTime _selectedWeekStart;
  DateTime _selectedMonthStart;
  DateTime _selectedYearStart;

  List<BloodGlucoseReading> get readings => _readings;

  BloodGlucosePeriod get selectedPeriod => _selectedPeriod;

  DateTime get selectedWeekStart => _selectedWeekStart;

  DateTime get selectedMonthStart => _selectedMonthStart;

  DateTime get selectedYearStart => _selectedYearStart;

  String get selectedPeriodLabel => bloodGlucosePeriodLabel(
        _selectedPeriod,
        weekStart: _selectedWeekStart,
        monthStart: _selectedMonthStart,
        yearStart: _selectedYearStart,
      );

  bool get showsPeriodNavigator =>
      _selectedPeriod == BloodGlucosePeriod.week ||
      _selectedPeriod == BloodGlucosePeriod.month ||
      _selectedPeriod == BloodGlucosePeriod.year;

  bool get canSelectPreviousPeriod => showsPeriodNavigator;

  bool get canSelectNextPeriod {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case BloodGlucosePeriod.week:
        return _selectedWeekStart.isBefore(bloodGlucoseWeekStart(now));
      case BloodGlucosePeriod.month:
        final thisMonth = bloodGlucoseMonthStart(now);
        return _selectedMonthStart.year < thisMonth.year ||
            (_selectedMonthStart.year == thisMonth.year &&
                _selectedMonthStart.month < thisMonth.month);
      case BloodGlucosePeriod.year:
        return _selectedYearStart.year < bloodGlucoseYearStart(now).year;
      case BloodGlucosePeriod.all:
        return false;
    }
  }

  String get previousPeriodTooltip => switch (_selectedPeriod) {
        BloodGlucosePeriod.week => 'Previous week',
        BloodGlucosePeriod.month => 'Previous month',
        BloodGlucosePeriod.year => 'Previous year',
        BloodGlucosePeriod.all => 'Previous',
      };

  String get nextPeriodTooltip => switch (_selectedPeriod) {
        BloodGlucosePeriod.week => 'Next week',
        BloodGlucosePeriod.month => 'Next month',
        BloodGlucosePeriod.year => 'Next year',
        BloodGlucosePeriod.all => 'Next',
      };

  BloodGlucoseReading? get latestReading =>
      _readings.isEmpty ? null : _readings.first;

  ({DateTime start, DateTime end}) get _range {
    final earliest =
        _readings.isEmpty ? null : _readings.last.recordedAt; // oldest
    return bloodGlucosePeriodRange(
      _selectedPeriod,
      DateTime.now(),
      earliestReadingAt: earliest,
      weekStart: _selectedWeekStart,
      monthStart: _selectedMonthStart,
      yearStart: _selectedYearStart,
    );
  }

  List<BloodGlucoseReading> get periodReadings {
    final range = _range;
    return bloodGlucoseReadingsInRange(_readings, range.start, range.end);
  }

  /// Newest reading in the selected period, else overall latest.
  BloodGlucoseReading? get heroReading {
    final inPeriod = periodReadings;
    if (inPeriod.isNotEmpty) {
      return inPeriod.first;
    }
    return latestReading;
  }

  double? get heroValueMgDl => heroReading?.valueMgDl;

  int get periodReadingCount => periodReadings.length;

  /// Newest minus oldest reading in the period (mg/dL). Null if < 2 readings.
  double? get periodChangeMgDl {
    final inPeriod = periodReadings;
    if (inPeriod.length < 2) {
      return null;
    }
    return inPeriod.first.valueMgDl - inPeriod.last.valueMgDl;
  }

  double? get periodAverageMgDl {
    final inPeriod = periodReadings;
    if (inPeriod.isEmpty) {
      return null;
    }
    var sum = 0.0;
    for (final reading in inPeriod) {
      sum += reading.valueMgDl;
    }
    return sum / inPeriod.length;
  }

  List<BloodGlucoseChartDay> get chartDays {
    final range = _range;
    if (_selectedPeriod == BloodGlucosePeriod.year) {
      return bloodGlucoseChartMonths(
        readings: _readings,
        start: range.start,
        end: range.end,
      );
    }
    return bloodGlucoseChartDays(
      readings: _readings,
      start: range.start,
      end: range.end,
    );
  }

  void selectPeriod(BloodGlucosePeriod period) {
    if (period == _selectedPeriod) {
      return;
    }
    _selectedPeriod = period;
    final now = DateTime.now();
    switch (period) {
      case BloodGlucosePeriod.week:
        _selectedWeekStart = bloodGlucoseWeekStart(now);
      case BloodGlucosePeriod.month:
        _selectedMonthStart = bloodGlucoseMonthStart(now);
      case BloodGlucosePeriod.year:
        _selectedYearStart = bloodGlucoseYearStart(now);
      case BloodGlucosePeriod.all:
        break;
    }
    notifyListeners();
  }

  void selectPreviousPeriod() {
    if (!canSelectPreviousPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case BloodGlucosePeriod.week:
        final start = bloodGlucoseLocalDateOnly(_selectedWeekStart);
        _selectedWeekStart = DateTime(start.year, start.month, start.day - 7);
      case BloodGlucosePeriod.month:
        final start = bloodGlucoseMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month - 1, 1);
      case BloodGlucosePeriod.year:
        final start = bloodGlucoseYearStart(_selectedYearStart);
        _selectedYearStart = DateTime(start.year - 1, 1, 1);
      case BloodGlucosePeriod.all:
        return;
    }
    notifyListeners();
  }

  void selectNextPeriod() {
    if (!canSelectNextPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case BloodGlucosePeriod.week:
        final start = bloodGlucoseLocalDateOnly(_selectedWeekStart);
        _selectedWeekStart = DateTime(start.year, start.month, start.day + 7);
      case BloodGlucosePeriod.month:
        final start = bloodGlucoseMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month + 1, 1);
      case BloodGlucosePeriod.year:
        final start = bloodGlucoseYearStart(_selectedYearStart);
        _selectedYearStart = DateTime(start.year + 1, 1, 1);
      case BloodGlucosePeriod.all:
        return;
    }
    notifyListeners();
  }

  /// Delta vs the next-older reading. Null if none older.
  double? changeVsPrevious(BloodGlucoseReading reading) {
    final index = _readings.indexWhere((r) => r.id == reading.id);
    if (index < 0 || index + 1 >= _readings.length) {
      return null;
    }
    return reading.valueMgDl - _readings[index + 1].valueMgDl;
  }

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

  Future<void> updateReading({
    required BloodGlucoseReading existing,
    required double valueMgDl,
    required DateTime recordedAt,
    String? context,
    String? notes,
  }) async {
    await _vitalsRepository.updateBloodGlucoseReading(
      BloodGlucoseReading(
        id: existing.id,
        patientId: existing.patientId,
        recordedAt: recordedAt.toUtc(),
        valueMgDl: valueMgDl,
        context: context?.trim().isEmpty ?? true ? null : context?.trim(),
        source: existing.source,
        notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
        deletedAt: existing.deletedAt,
      ),
    );
    await refresh();
  }

  Future<void> deleteReading(String id) async {
    await _vitalsRepository.deleteBloodGlucoseReading(id);
    await refresh();
  }
}
