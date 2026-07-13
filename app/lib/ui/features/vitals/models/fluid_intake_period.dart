import 'package:app/domain/models/fluid_intake_log.dart';

enum FluidIntakePeriod {
  last7Days,
  last30Days,
  month,
}

class FluidIntakeChartDay {
  const FluidIntakeChartDay({
    required this.day,
    required this.axisLabel,
    this.totalMl,
  });

  final DateTime day;
  final double? totalMl;
  final String axisLabel;
}

DateTime fluidIntakeLocalDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime fluidIntakeMonthStart(DateTime day) {
  final local = fluidIntakeLocalDateOnly(day);
  return DateTime(local.year, local.month, 1);
}

({DateTime start, DateTime end}) fluidIntakePeriodRange(
  FluidIntakePeriod period,
  DateTime today, {
  DateTime? earliestReadingAt,
  DateTime? monthStart,
}) {
  final endToday = fluidIntakeLocalDateOnly(today);
  switch (period) {
    case FluidIntakePeriod.last7Days:
      final start = endToday.subtract(const Duration(days: 6));
      return (start: start, end: endToday);
    case FluidIntakePeriod.last30Days:
      final start = endToday.subtract(const Duration(days: 29));
      return (start: start, end: endToday);
    case FluidIntakePeriod.month:
      final start = fluidIntakeMonthStart(monthStart ?? endToday);
      final monthEnd = DateTime(start.year, start.month + 1, 0);
      final end = monthEnd.isAfter(endToday) ? endToday : monthEnd;
      return (start: start, end: end);
  }
}

String fluidIntakePeriodLabel(
  FluidIntakePeriod period, {
  DateTime? monthStart,
  DateTime? today,
}) {
  final now = fluidIntakeLocalDateOnly(today ?? DateTime.now());
  switch (period) {
    case FluidIntakePeriod.last7Days:
      return 'Last 7 Days';
    case FluidIntakePeriod.last30Days:
      return 'Last 30 Days';
    case FluidIntakePeriod.month:
      final start = fluidIntakeMonthStart(monthStart ?? now);
      final thisMonth = fluidIntakeMonthStart(now);
      if (start.year == thisMonth.year && start.month == thisMonth.month) {
        return 'This Month';
      }
      final month = _shortMonths[start.month - 1];
      if (start.year == now.year) {
        return month;
      }
      return '$month ${start.year}';
  }
}

const _shortMonths = [
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

const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

List<FluidIntakeLog> fluidIntakeLogsInRange(
  List<FluidIntakeLog> logs,
  DateTime start,
  DateTime end,
) {
  return [
    for (final log in logs)
      if (!fluidIntakeLocalDateOnly(log.recordedAt).isBefore(start) &&
          !fluidIntakeLocalDateOnly(log.recordedAt).isAfter(end))
        log,
  ];
}

/// Daily totals (sum of logs) for each local day in [start]..[end].
Map<DateTime, double> fluidIntakeDailyTotals(
  List<FluidIntakeLog> logs,
  DateTime start,
  DateTime end,
) {
  final rangeStart = fluidIntakeLocalDateOnly(start);
  final rangeEnd = fluidIntakeLocalDateOnly(end);
  final totals = <DateTime, double>{};
  for (final log in logs) {
    final day = fluidIntakeLocalDateOnly(log.recordedAt);
    if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) {
      continue;
    }
    totals[day] = (totals[day] ?? 0) + log.fluidMl;
  }
  return totals;
}

List<FluidIntakeChartDay> fluidIntakeChartDays({
  required List<FluidIntakeLog> logs,
  required DateTime start,
  required DateTime end,
}) {
  final rangeStart = fluidIntakeLocalDateOnly(start);
  final rangeEnd = fluidIntakeLocalDateOnly(end);
  final totals = fluidIntakeDailyTotals(logs, rangeStart, rangeEnd);

  final totalDays = rangeEnd.difference(rangeStart).inDays;
  final days = <FluidIntakeChartDay>[];
  var cursor = rangeStart;
  while (!cursor.isAfter(rangeEnd)) {
    final day = fluidIntakeLocalDateOnly(cursor);
    final axisLabel = totalDays > 7
        ? '${day.day}'
        : _weekdayLetters[(day.weekday - 1) % 7];
    days.add(
      FluidIntakeChartDay(
        day: day,
        totalMl: totals[day],
        axisLabel: axisLabel,
      ),
    );
    cursor = DateTime(day.year, day.month, day.day + 1);
  }
  return days;
}
