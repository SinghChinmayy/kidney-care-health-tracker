import 'dart:math';

import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/ui/features/vitals/models/blood_glucose_period.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_context_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BloodGlucoseViewModel extends ChangeNotifier {
  BloodGlucoseViewModel({required VitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository,
        _selectedMonthStart = bloodGlucoseMonthStart(DateTime.now()) {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  List<BloodGlucoseReading> _readings = [];
  BloodGlucosePeriod _selectedPeriod = BloodGlucosePeriod.last7Days;
  DateTime _selectedMonthStart;

  List<BloodGlucoseReading> get readings => _readings;

  BloodGlucosePeriod get selectedPeriod => _selectedPeriod;

  DateTime get selectedMonthStart => _selectedMonthStart;

  String get selectedPeriodLabel => bloodGlucosePeriodLabel(
        _selectedPeriod,
        monthStart: _selectedMonthStart,
      );

  bool get showsPeriodNavigator =>
      _selectedPeriod == BloodGlucosePeriod.month;

  bool get canSelectPreviousPeriod => showsPeriodNavigator;

  bool get canSelectNextPeriod {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case BloodGlucosePeriod.last7Days:
      case BloodGlucosePeriod.last30Days:
        return false;
      case BloodGlucosePeriod.month:
        final thisMonth = bloodGlucoseMonthStart(now);
        return _selectedMonthStart.year < thisMonth.year ||
            (_selectedMonthStart.year == thisMonth.year &&
                _selectedMonthStart.month < thisMonth.month);
    }
  }

  String get previousPeriodTooltip => switch (_selectedPeriod) {
        BloodGlucosePeriod.last7Days => 'Previous',
        BloodGlucosePeriod.last30Days => 'Previous',
        BloodGlucosePeriod.month => 'Previous month',
      };

  String get nextPeriodTooltip => switch (_selectedPeriod) {
        BloodGlucosePeriod.last7Days => 'Next',
        BloodGlucosePeriod.last30Days => 'Next',
        BloodGlucosePeriod.month => 'Next month',
      };

  BloodGlucoseReading? get latestReading =>
      _readings.isEmpty ? null : _readings.first;

  ({DateTime start, DateTime end}) get _range {
    final earliest =
        _readings.isEmpty ? null : _readings.last.recordedAt;
    return bloodGlucosePeriodRange(
      _selectedPeriod,
      DateTime.now(),
      earliestReadingAt: earliest,
      monthStart: _selectedMonthStart,
    );
  }

  List<BloodGlucoseReading> get periodReadings {
    final range = _range;
    return bloodGlucoseReadingsInRange(_readings, range.start, range.end);
  }

  BloodGlucoseReading? get heroReading {
    final inPeriod = periodReadings;
    if (inPeriod.isNotEmpty) {
      return inPeriod.first;
    }
    return latestReading;
  }

  double? get heroValueMgDl => heroReading?.valueMgDl;

  String? get heroDateLabel {
    final reading = heroReading;
    if (reading == null) {
      return null;
    }
    return _heroDateLabel(reading.recordedAt);
  }

  String? get heroContextLabel {
    final context = heroReading?.context;
    if (context == null || context.isEmpty) {
      return null;
    }
    return formatBloodGlucoseContextLabel(context);
  }

  int get periodReadingCount => periodReadings.length;

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

  double? get periodMinMgDl {
    final inPeriod = periodReadings;
    if (inPeriod.isEmpty) {
      return null;
    }
    return inPeriod.map((r) => r.valueMgDl).reduce(min);
  }

  double? get periodMaxMgDl {
    final inPeriod = periodReadings;
    if (inPeriod.isEmpty) {
      return null;
    }
    return inPeriod.map((r) => r.valueMgDl).reduce(max);
  }

  double? get periodStdDevMgDl {
    final inPeriod = periodReadings;
    if (inPeriod.isEmpty) {
      return null;
    }
    final avg = periodAverageMgDl!;
    final variance = inPeriod
            .map((r) => pow(r.valueMgDl - avg, 2))
            .reduce((a, b) => a + b) /
        inPeriod.length;
    return sqrt(variance);
  }

  List<BloodGlucoseChartDay> get chartDays {
    final range = _range;
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
      case BloodGlucosePeriod.last7Days:
      case BloodGlucosePeriod.last30Days:
        break;
      case BloodGlucosePeriod.month:
        _selectedMonthStart = bloodGlucoseMonthStart(now);
    }
    notifyListeners();
  }

  void selectPreviousPeriod() {
    if (!canSelectPreviousPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case BloodGlucosePeriod.last7Days:
      case BloodGlucosePeriod.last30Days:
        return;
      case BloodGlucosePeriod.month:
        final start = bloodGlucoseMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month - 1, 1);
    }
    notifyListeners();
  }

  void selectNextPeriod() {
    if (!canSelectNextPeriod) {
      return;
    }
    switch (_selectedPeriod) {
      case BloodGlucosePeriod.last7Days:
      case BloodGlucosePeriod.last30Days:
        return;
      case BloodGlucosePeriod.month:
        final start = bloodGlucoseMonthStart(_selectedMonthStart);
        _selectedMonthStart = DateTime(start.year, start.month + 1, 1);
    }
    notifyListeners();
  }

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
