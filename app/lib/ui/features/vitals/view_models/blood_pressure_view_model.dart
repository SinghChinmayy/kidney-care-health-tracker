import 'dart:math';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/ui/features/vitals/models/blood_pressure_period.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BloodPressureViewModel extends ChangeNotifier {
  BloodPressureViewModel({required VitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository,
        _selectedMonthStart = bloodPressureMonthStart(DateTime.now()) {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  List<BloodPressureReading> _readings = [];
  BloodPressurePeriod _selectedPeriod = BloodPressurePeriod.last7Days;
  DateTime _selectedMonthStart;

  List<BloodPressureReading> get readings => _readings;

  BloodPressurePeriod get selectedPeriod => _selectedPeriod;

  DateTime get selectedMonthStart => _selectedMonthStart;

  String get selectedPeriodLabel => bloodPressurePeriodLabel(
        _selectedPeriod,
        monthStart: _selectedMonthStart,
      );

  bool get showsPeriodNavigator =>
      _selectedPeriod == BloodPressurePeriod.month;

  bool get canSelectPreviousPeriod => showsPeriodNavigator;

  bool get canSelectNextPeriod {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case BloodPressurePeriod.last7Days:
      case BloodPressurePeriod.last30Days:
        return false;
      case BloodPressurePeriod.month:
        final thisMonth = bloodPressureMonthStart(now);
        return _selectedMonthStart.year < thisMonth.year ||
            (_selectedMonthStart.year == thisMonth.year &&
                _selectedMonthStart.month < thisMonth.month);
    }
  }

  String get previousPeriodTooltip => switch (_selectedPeriod) {
        BloodPressurePeriod.last7Days => 'Previous',
        BloodPressurePeriod.last30Days => 'Previous',
        BloodPressurePeriod.month => 'Previous month',
      };

  String get nextPeriodTooltip => switch (_selectedPeriod) {
        BloodPressurePeriod.last7Days => 'Next',
        BloodPressurePeriod.last30Days => 'Next',
        BloodPressurePeriod.month => 'Next month',
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
      monthStart: _selectedMonthStart,
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

  /// Short date label for the hero reading (Today, Yesterday, Jul 10).
  String? get heroDateLabel {
    final reading = heroReading;
    if (reading == null) {
      return null;
    }
    return _heroDateLabel(reading.recordedAt);
  }

  /// Muted caption under the hero: date, heart rate, period average.
  String? get heroSubtitle {
    final reading = heroReading;
    if (reading == null) {
      return null;
    }

    final parts = <String>[_heroDateLabel(reading.recordedAt)];
    if (reading.heartRateBpm != null) {
      parts.add('${reading.heartRateBpm} bpm');
    }
    final avg = periodAverageDisplay;
    if (avg != null) {
      parts.add('avg $avg');
    }
    return parts.join(' · ');
  }

  /// Combined period average as `sys/dia`, or null when incomplete.
  String? get periodAverageDisplay {
    final avgSys = periodAverageSystolic;
    final avgDia = periodAverageDiastolic;
    if (avgSys == null || avgDia == null) {
      return null;
    }
    return '${avgSys.round()}/${avgDia.round()}';
  }

  /// Compact min–max range for systolic and diastolic in the period.
  String? get periodRangeDisplay {
    final minSys = periodMinSystolic;
    final maxSys = periodMaxSystolic;
    final minDia = periodMinDiastolic;
    final maxDia = periodMaxDiastolic;
    if (minSys == null ||
        maxSys == null ||
        minDia == null ||
        maxDia == null) {
      return null;
    }
    return '$minSys–$maxSys / $minDia–$maxDia';
  }

  int get periodReadingCount => periodReadings.length;

  List<BloodPressureReading> get _periodWithSystolic => [
        for (final reading in periodReadings)
          if (reading.systolic != null) reading,
      ];

  List<BloodPressureReading> get _periodWithDiastolic => [
        for (final reading in periodReadings)
          if (reading.diastolic != null) reading,
      ];

  List<BloodPressureReading> get _periodWithHr => [
        for (final reading in periodReadings)
          if (reading.heartRateBpm != null) reading,
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
    if (withSys.isEmpty) return null;
    var sum = 0;
    for (final r in withSys) sum += r.systolic!;
    return sum / withSys.length;
  }

  int? get periodMinSystolic {
    final withSys = _periodWithSystolic;
    if (withSys.isEmpty) return null;
    return withSys.map((r) => r.systolic!).reduce((a, b) => a < b ? a : b);
  }

  int? get periodMaxSystolic {
    final withSys = _periodWithSystolic;
    if (withSys.isEmpty) return null;
    return withSys.map((r) => r.systolic!).reduce((a, b) => a > b ? a : b);
  }

  double? get periodAverageDiastolic {
    final withDia = _periodWithDiastolic;
    if (withDia.isEmpty) return null;
    var sum = 0;
    for (final r in withDia) sum += r.diastolic!;
    return sum / withDia.length;
  }

  int? get periodMinDiastolic {
    final withDia = _periodWithDiastolic;
    if (withDia.isEmpty) return null;
    return withDia.map((r) => r.diastolic!).reduce((a, b) => a < b ? a : b);
  }

  int? get periodMaxDiastolic {
    final withDia = _periodWithDiastolic;
    if (withDia.isEmpty) return null;
    return withDia.map((r) => r.diastolic!).reduce((a, b) => a > b ? a : b);
  }

  double? get periodStdDevSystolic {
    final withSys = _periodWithSystolic;
    if (withSys.isEmpty) return null;
    final avg = periodAverageSystolic!;
    final variance = withSys.map((r) => pow(r.systolic! - avg, 2)).reduce((a, b) => a + b) / withSys.length;
    return sqrt(variance);
  }

  double? get periodStdDevDiastolic {
    final withDia = _periodWithDiastolic;
    if (withDia.isEmpty) return null;
    final avg = periodAverageDiastolic!;
    final variance = withDia.map((r) => pow(r.diastolic! - avg, 2)).reduce((a, b) => a + b) / withDia.length;
    return sqrt(variance);
  }

  double? get periodAverageHr {
    final withHr = _periodWithHr;
    if (withHr.isEmpty) return null;
    var sum = 0;
    for (final r in withHr) sum += r.heartRateBpm!;
    return sum / withHr.length;
  }

  int? get periodMinHr {
    final withHr = _periodWithHr;
    if (withHr.isEmpty) return null;
    return withHr.map((r) => r.heartRateBpm!).reduce((a, b) => a < b ? a : b);
  }

  int? get periodMaxHr {
    final withHr = _periodWithHr;
    if (withHr.isEmpty) return null;
    return withHr.map((r) => r.heartRateBpm!).reduce((a, b) => a > b ? a : b);
  }

  List<BloodPressureChartDay> get chartDays {
    final range = _range;
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
      case BloodPressurePeriod.last7Days:
      case BloodPressurePeriod.last30Days:
        break;
      case BloodPressurePeriod.month:
        _selectedMonthStart = bloodPressureMonthStart(now);
    }
    notifyListeners();
  }

  void selectPreviousPeriod() {
    if (!canSelectPreviousPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case BloodPressurePeriod.last7Days:
      case BloodPressurePeriod.last30Days:
        return;
      case BloodPressurePeriod.month:
        final start = bloodPressureMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month - 1, 1);
    }
    notifyListeners();
  }

  void selectNextPeriod() {
    if (!canSelectNextPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case BloodPressurePeriod.last7Days:
      case BloodPressurePeriod.last30Days:
        return;
      case BloodPressurePeriod.month:
        final start = bloodPressureMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month + 1, 1);
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
