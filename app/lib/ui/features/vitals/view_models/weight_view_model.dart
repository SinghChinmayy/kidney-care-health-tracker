import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/ui/features/vitals/models/weight_period.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class WeightViewModel extends ChangeNotifier {
  WeightViewModel({required VitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository,
        _selectedWeekStart = weightWeekStart(DateTime.now()),
        _selectedMonthStart = weightMonthStart(DateTime.now()),
        _selectedYearStart = weightYearStart(DateTime.now()) {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  List<WeightReading> _readings = [];
  bool _isOnDialysis = false;
  WeightPeriod _selectedPeriod = WeightPeriod.week;
  DateTime _selectedWeekStart;
  DateTime _selectedMonthStart;
  DateTime _selectedYearStart;

  List<WeightReading> get readings => _readings;

  bool get isOnDialysis => _isOnDialysis;

  WeightPeriod get selectedPeriod => _selectedPeriod;

  DateTime get selectedWeekStart => _selectedWeekStart;

  DateTime get selectedMonthStart => _selectedMonthStart;

  DateTime get selectedYearStart => _selectedYearStart;

  String get selectedPeriodLabel => weightPeriodLabel(
        _selectedPeriod,
        weekStart: _selectedWeekStart,
        monthStart: _selectedMonthStart,
        yearStart: _selectedYearStart,
      );

  bool get showsPeriodNavigator =>
      _selectedPeriod == WeightPeriod.week ||
      _selectedPeriod == WeightPeriod.month ||
      _selectedPeriod == WeightPeriod.year;

  bool get canSelectPreviousPeriod => showsPeriodNavigator;

  bool get canSelectNextPeriod {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case WeightPeriod.week:
        return _selectedWeekStart.isBefore(weightWeekStart(now));
      case WeightPeriod.month:
        final thisMonth = weightMonthStart(now);
        return _selectedMonthStart.year < thisMonth.year ||
            (_selectedMonthStart.year == thisMonth.year &&
                _selectedMonthStart.month < thisMonth.month);
      case WeightPeriod.year:
        return _selectedYearStart.year < weightYearStart(now).year;
      case WeightPeriod.all:
        return false;
    }
  }

  String get previousPeriodTooltip => switch (_selectedPeriod) {
        WeightPeriod.week => 'Previous week',
        WeightPeriod.month => 'Previous month',
        WeightPeriod.year => 'Previous year',
        WeightPeriod.all => 'Previous',
      };

  String get nextPeriodTooltip => switch (_selectedPeriod) {
        WeightPeriod.week => 'Next week',
        WeightPeriod.month => 'Next month',
        WeightPeriod.year => 'Next year',
        WeightPeriod.all => 'Next',
      };

  WeightReading? get latestReading =>
      _readings.isEmpty ? null : _readings.first;

  ({DateTime start, DateTime end}) get _range {
    final earliest =
        _readings.isEmpty ? null : _readings.last.recordedAt; // oldest
    return weightPeriodRange(
      _selectedPeriod,
      DateTime.now(),
      earliestReadingAt: earliest,
      weekStart: _selectedWeekStart,
      monthStart: _selectedMonthStart,
      yearStart: _selectedYearStart,
    );
  }

  List<WeightReading> get periodReadings {
    final range = _range;
    return weightReadingsInRange(_readings, range.start, range.end);
  }

  /// Newest reading in the selected period, else overall latest.
  WeightReading? get heroReading {
    final inPeriod = periodReadings;
    if (inPeriod.isNotEmpty) {
      return inPeriod.first;
    }
    return latestReading;
  }

  double? get heroWeightKg => heroReading?.valueKg;

  int get periodReadingCount => periodReadings.length;

  /// Newest minus oldest reading in the period (kg). Null if < 2 readings.
  double? get periodChangeKg {
    final inPeriod = periodReadings;
    if (inPeriod.length < 2) {
      return null;
    }
    return inPeriod.first.valueKg - inPeriod.last.valueKg;
  }

  double? get periodAverageKg {
    final inPeriod = periodReadings;
    if (inPeriod.isEmpty) {
      return null;
    }
    var sum = 0.0;
    for (final reading in inPeriod) {
      sum += reading.valueKg;
    }
    return sum / inPeriod.length;
  }

  List<WeightChartDay> get chartDays {
    final range = _range;
    if (_selectedPeriod == WeightPeriod.year) {
      return weightChartMonths(
        readings: _readings,
        start: range.start,
        end: range.end,
      );
    }
    return weightChartDays(
      readings: _readings,
      start: range.start,
      end: range.end,
    );
  }

  void selectPeriod(WeightPeriod period) {
    if (period == _selectedPeriod) {
      return;
    }
    _selectedPeriod = period;
    final now = DateTime.now();
    switch (period) {
      case WeightPeriod.week:
        _selectedWeekStart = weightWeekStart(now);
      case WeightPeriod.month:
        _selectedMonthStart = weightMonthStart(now);
      case WeightPeriod.year:
        _selectedYearStart = weightYearStart(now);
      case WeightPeriod.all:
        break;
    }
    notifyListeners();
  }

  void selectPreviousPeriod() {
    if (!canSelectPreviousPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case WeightPeriod.week:
        final start = weightLocalDateOnly(_selectedWeekStart);
        _selectedWeekStart = DateTime(start.year, start.month, start.day - 7);
      case WeightPeriod.month:
        final start = weightMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month - 1, 1);
      case WeightPeriod.year:
        final start = weightYearStart(_selectedYearStart);
        _selectedYearStart = DateTime(start.year - 1, 1, 1);
      case WeightPeriod.all:
        return;
    }
    notifyListeners();
  }

  void selectNextPeriod() {
    if (!canSelectNextPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case WeightPeriod.week:
        final start = weightLocalDateOnly(_selectedWeekStart);
        _selectedWeekStart = DateTime(start.year, start.month, start.day + 7);
      case WeightPeriod.month:
        final start = weightMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month + 1, 1);
      case WeightPeriod.year:
        final start = weightYearStart(_selectedYearStart);
        _selectedYearStart = DateTime(start.year + 1, 1, 1);
      case WeightPeriod.all:
        return;
    }
    notifyListeners();
  }

  /// Delta vs the next-older reading (positive = gained). Null if none older.
  double? changeVsPrevious(WeightReading reading) {
    final index = _readings.indexWhere((r) => r.id == reading.id);
    if (index < 0 || index + 1 >= _readings.length) {
      return null;
    }
    return reading.valueKg - _readings[index + 1].valueKg;
  }

  Future<void> refresh() async {
    final patient = await _vitalsRepository.getCurrentPatient();
    _isOnDialysis = patient != null && patient.dialysisType != 'none';
    _readings = await _vitalsRepository.getWeightReadings();
    notifyListeners();
  }

  Future<void> addReading({
    required double valueKg,
    required String dialysisTiming,
    DateTime? recordedAt,
    String? weightContext,
    String? notes,
  }) async {
    final reading = WeightReading(
      id: const Uuid().v4(),
      recordedAt: (recordedAt ?? DateTime.now()).toUtc(),
      valueKg: valueKg,
      dialysisTiming: dialysisTiming,
      weightContext: weightContext?.trim().isEmpty ?? true
          ? null
          : weightContext?.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    await _vitalsRepository.addWeightReading(reading);
    await refresh();
  }

  Future<void> updateReading({
    required WeightReading existing,
    required double valueKg,
    required String dialysisTiming,
    required DateTime recordedAt,
    String? weightContext,
    String? notes,
  }) async {
    await _vitalsRepository.updateWeightReading(
      WeightReading(
        id: existing.id,
        patientId: existing.patientId,
        recordedAt: recordedAt.toUtc(),
        valueKg: valueKg,
        dialysisTiming: dialysisTiming,
        weightContext: weightContext?.trim().isEmpty ?? true
            ? null
            : weightContext?.trim(),
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
    await _vitalsRepository.deleteWeightReading(id);
    await refresh();
  }
}
