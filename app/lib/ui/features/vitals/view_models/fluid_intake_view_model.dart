import 'dart:math';

import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:app/domain/models/patient_preferences.dart';
import 'package:app/ui/features/vitals/models/fluid_intake_period.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class FluidIntakeViewModel extends ChangeNotifier {
  FluidIntakeViewModel({required VitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository,
        _selectedMonthStart = fluidIntakeMonthStart(DateTime.now()) {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  List<FluidIntakeLog> _logs = [];
  int _dailyWaterGoalMl = PatientPreferences.defaultDailyWaterGoalMl;
  FluidIntakePeriod _selectedPeriod = FluidIntakePeriod.last7Days;
  DateTime _selectedMonthStart;

  List<FluidIntakeLog> get logs => _logs;

  int get dailyWaterGoalMl => _dailyWaterGoalMl;

  FluidIntakePeriod get selectedPeriod => _selectedPeriod;

  DateTime get selectedMonthStart => _selectedMonthStart;

  String get selectedPeriodLabel => fluidIntakePeriodLabel(
        _selectedPeriod,
        monthStart: _selectedMonthStart,
      );

  bool get showsPeriodNavigator =>
      _selectedPeriod == FluidIntakePeriod.month;

  bool get canSelectPreviousPeriod => showsPeriodNavigator;

  bool get canSelectNextPeriod {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case FluidIntakePeriod.last7Days:
      case FluidIntakePeriod.last30Days:
        return false;
      case FluidIntakePeriod.month:
        final thisMonth = fluidIntakeMonthStart(now);
        return _selectedMonthStart.year < thisMonth.year ||
            (_selectedMonthStart.year == thisMonth.year &&
                _selectedMonthStart.month < thisMonth.month);
    }
  }

  String get previousPeriodTooltip => switch (_selectedPeriod) {
        FluidIntakePeriod.last7Days => 'Previous',
        FluidIntakePeriod.last30Days => 'Previous',
        FluidIntakePeriod.month => 'Previous month',
      };

  String get nextPeriodTooltip => switch (_selectedPeriod) {
        FluidIntakePeriod.last7Days => 'Next',
        FluidIntakePeriod.last30Days => 'Next',
        FluidIntakePeriod.month => 'Next month',
      };

  FluidIntakeLog? get latestLog => _logs.isEmpty ? null : _logs.first;

  ({DateTime start, DateTime end}) get _range {
    final earliest = _logs.isEmpty ? null : _logs.last.recordedAt;
    return fluidIntakePeriodRange(
      _selectedPeriod,
      DateTime.now(),
      earliestReadingAt: earliest,
      monthStart: _selectedMonthStart,
    );
  }

  List<FluidIntakeLog> get periodLogs {
    final range = _range;
    return fluidIntakeLogsInRange(_logs, range.start, range.end);
  }

  List<double> get _periodDailyTotalsWithData {
    final range = _range;
    final totals = fluidIntakeDailyTotals(_logs, range.start, range.end);
    return totals.values.toList();
  }

  double totalMlOnLocalDate(DateTime localDate) {
    final day = DateTime(localDate.year, localDate.month, localDate.day);
    var total = 0.0;
    for (final log in _logs) {
      final local = log.recordedAt.toLocal();
      final logDay = DateTime(local.year, local.month, local.day);
      if (logDay == day) {
        total += log.fluidMl;
      }
    }
    return total;
  }

  /// Hero shows today's total when today is in range; else newest day total.
  double? get heroTotalMl {
    final range = _range;
    final today = fluidIntakeLocalDateOnly(DateTime.now());
    if (!today.isBefore(range.start) && !today.isAfter(range.end)) {
      final todayTotal = totalMlOnLocalDate(today);
      if (todayTotal > 0 || periodLogs.isNotEmpty) {
        return todayTotal;
      }
      return null;
    }
    final inPeriod = periodLogs;
    if (inPeriod.isEmpty) {
      return null;
    }
    return totalMlOnLocalDate(inPeriod.first.recordedAt);
  }

  String? get heroMetaLabel {
    final range = _range;
    final today = fluidIntakeLocalDateOnly(DateTime.now());
    if (!today.isBefore(range.start) && !today.isAfter(range.end)) {
      if (heroTotalMl == null && periodLogs.isEmpty) {
        return null;
      }
      return 'Today · goal $_dailyWaterGoalMl ml';
    }
    final inPeriod = periodLogs;
    if (inPeriod.isEmpty) {
      return null;
    }
    return '${_heroDateLabel(inPeriod.first.recordedAt)} · goal $_dailyWaterGoalMl ml';
  }

  int get periodLogCount => periodLogs.length;

  double? get periodAverageDailyMl {
    final totals = _periodDailyTotalsWithData;
    if (totals.isEmpty) {
      return null;
    }
    return totals.reduce((a, b) => a + b) / totals.length;
  }

  double? get periodMinDailyMl {
    final totals = _periodDailyTotalsWithData;
    if (totals.isEmpty) {
      return null;
    }
    return totals.reduce(min);
  }

  double? get periodMaxDailyMl {
    final totals = _periodDailyTotalsWithData;
    if (totals.isEmpty) {
      return null;
    }
    return totals.reduce(max);
  }

  double? get periodStdDevDailyMl {
    final totals = _periodDailyTotalsWithData;
    if (totals.isEmpty) {
      return null;
    }
    final avg = periodAverageDailyMl!;
    final variance =
        totals.map((v) => pow(v - avg, 2)).reduce((a, b) => a + b) /
            totals.length;
    return sqrt(variance);
  }

  List<FluidIntakeChartDay> get chartDays {
    final range = _range;
    return fluidIntakeChartDays(
      logs: _logs,
      start: range.start,
      end: range.end,
    );
  }

  void selectPeriod(FluidIntakePeriod period) {
    if (period == _selectedPeriod) {
      return;
    }
    _selectedPeriod = period;
    final now = DateTime.now();
    switch (period) {
      case FluidIntakePeriod.last7Days:
      case FluidIntakePeriod.last30Days:
        break;
      case FluidIntakePeriod.month:
        _selectedMonthStart = fluidIntakeMonthStart(now);
    }
    notifyListeners();
  }

  void selectPreviousPeriod() {
    if (!canSelectPreviousPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case FluidIntakePeriod.last7Days:
      case FluidIntakePeriod.last30Days:
        return;
      case FluidIntakePeriod.month:
        final start = fluidIntakeMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month - 1, 1);
    }
    notifyListeners();
  }

  void selectNextPeriod() {
    if (!canSelectNextPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case FluidIntakePeriod.last7Days:
      case FluidIntakePeriod.last30Days:
        return;
      case FluidIntakePeriod.month:
        final start = fluidIntakeMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month + 1, 1);
    }
    notifyListeners();
  }

  double? changeVsPrevious(FluidIntakeLog log) {
    final index = _logs.indexWhere((r) => r.id == log.id);
    if (index < 0 || index + 1 >= _logs.length) {
      return null;
    }
    return log.fluidMl - _logs[index + 1].fluidMl;
  }

  Future<void> refresh() async {
    _logs = await _vitalsRepository.getFluidIntakeLogs();
    final prefs = await _vitalsRepository.getCurrentPreferences();
    _dailyWaterGoalMl =
        prefs?.dailyWaterGoalMl ?? PatientPreferences.defaultDailyWaterGoalMl;
    notifyListeners();
  }

  Future<void> addLog({
    required double fluidMl,
    String? notes,
    DateTime? recordedAt,
  }) async {
    final log = FluidIntakeLog(
      id: const Uuid().v4(),
      recordedAt: (recordedAt ?? DateTime.now()).toUtc(),
      fluidMl: fluidMl,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    await _vitalsRepository.addFluidIntakeLog(log);
    await refresh();
  }

  Future<void> updateLog({
    required FluidIntakeLog existing,
    required double fluidMl,
    required DateTime recordedAt,
    String? notes,
  }) async {
    await _vitalsRepository.updateFluidIntakeLog(
      FluidIntakeLog(
        id: existing.id,
        patientId: existing.patientId,
        recordedAt: recordedAt.toUtc(),
        fluidMl: fluidMl,
        source: existing.source,
        notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
        deletedAt: existing.deletedAt,
      ),
    );
    await refresh();
  }

  Future<void> deleteLog(String id) async {
    await _vitalsRepository.deleteFluidIntakeLog(id);
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
