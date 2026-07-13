import 'dart:math';

import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/ui/features/vitals/models/weight_period.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class WeightViewModel extends ChangeNotifier {
  WeightViewModel({required VitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository,
        _selectedMonthStart = weightMonthStart(DateTime.now()) {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  List<WeightReading> _readings = [];
  bool _isOnDialysis = false;
  WeightPeriod _selectedPeriod = WeightPeriod.last7Days;
  DateTime _selectedMonthStart;

  List<WeightReading> get readings => _readings;

  bool get isOnDialysis => _isOnDialysis;

  WeightPeriod get selectedPeriod => _selectedPeriod;

  DateTime get selectedMonthStart => _selectedMonthStart;

  String get selectedPeriodLabel => weightPeriodLabel(
        _selectedPeriod,
        monthStart: _selectedMonthStart,
      );

  bool get showsPeriodNavigator =>
      _selectedPeriod == WeightPeriod.month;

  bool get canSelectPreviousPeriod => showsPeriodNavigator;

  bool get canSelectNextPeriod {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case WeightPeriod.last7Days:
      case WeightPeriod.last30Days:
        return false;
      case WeightPeriod.month:
        final thisMonth = weightMonthStart(now);
        return _selectedMonthStart.year < thisMonth.year ||
            (_selectedMonthStart.year == thisMonth.year &&
                _selectedMonthStart.month < thisMonth.month);
    }
  }

  String get previousPeriodTooltip => switch (_selectedPeriod) {
        WeightPeriod.last7Days => 'Previous',
        WeightPeriod.last30Days => 'Previous',
        WeightPeriod.month => 'Previous month',
      };

  String get nextPeriodTooltip => switch (_selectedPeriod) {
        WeightPeriod.last7Days => 'Next',
        WeightPeriod.last30Days => 'Next',
        WeightPeriod.month => 'Next month',
      };

  WeightReading? get latestReading =>
      _readings.isEmpty ? null : _readings.first;

  ({DateTime start, DateTime end}) get _range {
    final earliest =
        _readings.isEmpty ? null : _readings.last.recordedAt;
    return weightPeriodRange(
      _selectedPeriod,
      DateTime.now(),
      earliestReadingAt: earliest,
      monthStart: _selectedMonthStart,
    );
  }

  List<WeightReading> get periodReadings {
    final range = _range;
    return weightReadingsInRange(_readings, range.start, range.end);
  }

  WeightReading? get heroReading {
    final inPeriod = periodReadings;
    if (inPeriod.isNotEmpty) {
      return inPeriod.first;
    }
    return latestReading;
  }

  double? get heroWeightKg => heroReading?.valueKg;

  String? get heroDateLabel {
    final reading = heroReading;
    if (reading == null) {
      return null;
    }
    return _heroDateLabel(reading.recordedAt);
  }

  /// Compact caption for the summary strip, e.g. `Today · Post · PM`.
  String? get heroMetaLabel {
    final reading = heroReading;
    if (reading == null) {
      return null;
    }
    final parts = <String>[
      _heroDateLabel(reading.recordedAt),
      formatCompactDialysisTimingLabel(reading.dialysisTiming),
      if (reading.weightContext != null && reading.weightContext!.isNotEmpty)
        formatCompactWeightContextLabel(reading.weightContext!),
    ];
    return parts.join(' · ');
  }

  int get periodReadingCount => periodReadings.length;

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

  double? get periodMinKg {
    final inPeriod = periodReadings;
    if (inPeriod.isEmpty) {
      return null;
    }
    return inPeriod.map((r) => r.valueKg).reduce(min);
  }

  double? get periodMaxKg {
    final inPeriod = periodReadings;
    if (inPeriod.isEmpty) {
      return null;
    }
    return inPeriod.map((r) => r.valueKg).reduce(max);
  }

  double? get periodStdDevKg {
    final inPeriod = periodReadings;
    if (inPeriod.isEmpty) {
      return null;
    }
    final avg = periodAverageKg!;
    final variance = inPeriod
            .map((r) => pow(r.valueKg - avg, 2))
            .reduce((a, b) => a + b) /
        inPeriod.length;
    return sqrt(variance);
  }

  List<WeightChartDay> get chartDays {
    final range = _range;
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
      case WeightPeriod.last7Days:
      case WeightPeriod.last30Days:
        break;
      case WeightPeriod.month:
        _selectedMonthStart = weightMonthStart(now);
    }
    notifyListeners();
  }

  void selectPreviousPeriod() {
    if (!canSelectPreviousPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case WeightPeriod.last7Days:
      case WeightPeriod.last30Days:
        return;
      case WeightPeriod.month:
        final start = weightMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month - 1, 1);
    }
    notifyListeners();
  }

  void selectNextPeriod() {
    if (!canSelectNextPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case WeightPeriod.last7Days:
      case WeightPeriod.last30Days:
        return;
      case WeightPeriod.month:
        final start = weightMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month + 1, 1);
    }
    notifyListeners();
  }

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

  String _heroDateLabel(DateTime recordedAt) {
    final local = recordedAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(local.year, local.month, local.day);
    if (date == today) {
      return 'Today';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == yesterday) {
      return 'Yesterday';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}';
  }
}
