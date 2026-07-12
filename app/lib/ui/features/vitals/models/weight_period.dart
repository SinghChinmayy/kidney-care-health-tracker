import 'package:app/domain/models/weight_reading.dart';

enum WeightPeriod {
  week,
  month,
  year,
  all,
}

class WeightChartDay {
  const WeightChartDay({
    required this.day,
    required this.axisLabel,
    this.valueKg,
  });

  /// Local calendar day (or month start for monthly buckets).
  final DateTime day;
  final double? valueKg;

  /// X-axis tick label (weekday letter or month initial).
  final String axisLabel;
}

DateTime weightLocalDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Monday (local) of the week that contains [day].
DateTime weightWeekStart(DateTime day) {
  final local = weightLocalDateOnly(day);
  return local.subtract(Duration(days: local.weekday - 1));
}

/// First day of the calendar month that contains [day].
DateTime weightMonthStart(DateTime day) {
  final local = weightLocalDateOnly(day);
  return DateTime(local.year, local.month, 1);
}

/// January 1 of the calendar year that contains [day].
DateTime weightYearStart(DateTime day) {
  final local = weightLocalDateOnly(day);
  return DateTime(local.year, 1, 1);
}

/// Inclusive local-date range for [period].
///
/// Week/month/year windows use [weekStart]/[monthStart]/[yearStart]. Past
/// periods use the full calendar window; the current period ends on [today].
({DateTime start, DateTime end}) weightPeriodRange(
  WeightPeriod period,
  DateTime today, {
  DateTime? earliestReadingAt,
  DateTime? weekStart,
  DateTime? monthStart,
  DateTime? yearStart,
}) {
  final endToday = weightLocalDateOnly(today);
  switch (period) {
    case WeightPeriod.week:
      final start = weightWeekStart(weekStart ?? endToday);
      final weekEnd = DateTime(start.year, start.month, start.day + 6);
      final end = weekEnd.isAfter(endToday) ? endToday : weekEnd;
      return (start: start, end: end);
    case WeightPeriod.month:
      final start = weightMonthStart(monthStart ?? endToday);
      final monthEnd = DateTime(start.year, start.month + 1, 0);
      final end = monthEnd.isAfter(endToday) ? endToday : monthEnd;
      return (start: start, end: end);
    case WeightPeriod.year:
      final start = weightYearStart(yearStart ?? endToday);
      final yearEnd = DateTime(start.year, 12, 31);
      final end = yearEnd.isAfter(endToday) ? endToday : yearEnd;
      return (start: start, end: end);
    case WeightPeriod.all:
      if (earliestReadingAt == null) {
        return (start: endToday, end: endToday);
      }
      final start = weightLocalDateOnly(earliestReadingAt);
      if (start.isAfter(endToday)) {
        return (start: endToday, end: endToday);
      }
      return (start: start, end: endToday);
  }
}

String weightPeriodLabel(
  WeightPeriod period, {
  DateTime? weekStart,
  DateTime? monthStart,
  DateTime? yearStart,
  DateTime? today,
}) {
  final now = weightLocalDateOnly(today ?? DateTime.now());
  switch (period) {
    case WeightPeriod.week:
      final start = weightWeekStart(weekStart ?? now);
      final thisWeek = weightWeekStart(now);
      if (start == thisWeek) {
        return 'This Week';
      }
      final end = DateTime(start.year, start.month, start.day + 6);
      return _formatWeekRangeLabel(start, end);
    case WeightPeriod.month:
      final start = weightMonthStart(monthStart ?? now);
      final thisMonth = weightMonthStart(now);
      if (start.year == thisMonth.year && start.month == thisMonth.month) {
        return 'This Month';
      }
      final month = _shortMonths[start.month - 1];
      if (start.year == now.year) {
        return month;
      }
      return '$month ${start.year}';
    case WeightPeriod.year:
      final start = weightYearStart(yearStart ?? now);
      if (start.year == now.year) {
        return 'This Year';
      }
      return '${start.year}';
    case WeightPeriod.all:
      return 'All Time';
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

String _formatWeekRangeLabel(DateTime start, DateTime end) {
  final startMonth = _shortMonths[start.month - 1];
  final endMonth = _shortMonths[end.month - 1];
  if (start.year == end.year && start.month == end.month) {
    return '$startMonth ${start.day}–${end.day}';
  }
  if (start.year == end.year) {
    return '$startMonth ${start.day} – $endMonth ${end.day}';
  }
  return '$startMonth ${start.day}, ${start.year} – $endMonth ${end.day}, ${end.year}';
}

const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _monthLetters = [
  'J',
  'F',
  'M',
  'A',
  'M',
  'J',
  'J',
  'A',
  'S',
  'O',
  'N',
  'D',
];

List<WeightReading> weightReadingsInRange(
  List<WeightReading> readings,
  DateTime start,
  DateTime end,
) {
  return [
    for (final reading in readings)
      if (!weightLocalDateOnly(reading.recordedAt).isBefore(start) &&
          !weightLocalDateOnly(reading.recordedAt).isAfter(end))
        reading,
  ];
}

/// One bucket per local day from [start] to [end]; value is latest reading that day.
List<WeightChartDay> weightChartDays({
  required List<WeightReading> readings,
  required DateTime start,
  required DateTime end,
}) {
  final rangeStart = weightLocalDateOnly(start);
  final rangeEnd = weightLocalDateOnly(end);

  final latestByDay = <DateTime, WeightReading>{};
  for (final reading in readings) {
    final day = weightLocalDateOnly(reading.recordedAt);
    if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) {
      continue;
    }
    final existing = latestByDay[day];
    if (existing == null ||
        reading.recordedAt.isAfter(existing.recordedAt)) {
      latestByDay[day] = reading;
    }
  }

  final days = <WeightChartDay>[];
  var cursor = rangeStart;
  while (!cursor.isAfter(rangeEnd)) {
    final day = weightLocalDateOnly(cursor);
    days.add(
      WeightChartDay(
        day: day,
        valueKg: latestByDay[day]?.valueKg,
        axisLabel: _weekdayLetters[(day.weekday - 1) % 7],
      ),
    );
    cursor = DateTime(day.year, day.month, day.day + 1);
  }
  return days;
}

/// One bucket per calendar month from [start] to [end]; value is latest that month.
List<WeightChartDay> weightChartMonths({
  required List<WeightReading> readings,
  required DateTime start,
  required DateTime end,
}) {
  final rangeStart = weightMonthStart(start);
  final rangeEnd = weightLocalDateOnly(end);

  final latestByMonth = <DateTime, WeightReading>{};
  for (final reading in readings) {
    final day = weightLocalDateOnly(reading.recordedAt);
    if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) {
      continue;
    }
    final month = weightMonthStart(day);
    final existing = latestByMonth[month];
    if (existing == null ||
        reading.recordedAt.isAfter(existing.recordedAt)) {
      latestByMonth[month] = reading;
    }
  }

  final months = <WeightChartDay>[];
  var cursor = rangeStart;
  while (!cursor.isAfter(rangeEnd)) {
    final month = weightMonthStart(cursor);
    months.add(
      WeightChartDay(
        day: month,
        valueKg: latestByMonth[month]?.valueKg,
        axisLabel: _monthLetters[month.month - 1],
      ),
    );
    cursor = DateTime(month.year, month.month + 1, 1);
  }
  return months;
}
