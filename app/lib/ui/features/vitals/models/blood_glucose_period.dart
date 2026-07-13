import 'package:app/domain/models/blood_glucose_reading.dart';

enum BloodGlucosePeriod {
  week,
  month,
  year,
  all,
}

class BloodGlucoseChartDay {
  const BloodGlucoseChartDay({
    required this.day,
    required this.axisLabel,
    this.valueMgDl,
  });

  /// Local calendar day (or month start for monthly buckets).
  final DateTime day;
  final double? valueMgDl;

  /// X-axis tick label (weekday letter or month initial).
  final String axisLabel;
}

DateTime bloodGlucoseLocalDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Monday (local) of the week that contains [day].
DateTime bloodGlucoseWeekStart(DateTime day) {
  final local = bloodGlucoseLocalDateOnly(day);
  return local.subtract(Duration(days: local.weekday - 1));
}

/// First day of the calendar month that contains [day].
DateTime bloodGlucoseMonthStart(DateTime day) {
  final local = bloodGlucoseLocalDateOnly(day);
  return DateTime(local.year, local.month, 1);
}

/// January 1 of the calendar year that contains [day].
DateTime bloodGlucoseYearStart(DateTime day) {
  final local = bloodGlucoseLocalDateOnly(day);
  return DateTime(local.year, 1, 1);
}

/// Inclusive local-date range for [period].
({DateTime start, DateTime end}) bloodGlucosePeriodRange(
  BloodGlucosePeriod period,
  DateTime today, {
  DateTime? earliestReadingAt,
  DateTime? weekStart,
  DateTime? monthStart,
  DateTime? yearStart,
}) {
  final endToday = bloodGlucoseLocalDateOnly(today);
  switch (period) {
    case BloodGlucosePeriod.week:
      final start = bloodGlucoseWeekStart(weekStart ?? endToday);
      final weekEnd = DateTime(start.year, start.month, start.day + 6);
      final end = weekEnd.isAfter(endToday) ? endToday : weekEnd;
      return (start: start, end: end);
    case BloodGlucosePeriod.month:
      final start = bloodGlucoseMonthStart(monthStart ?? endToday);
      final monthEnd = DateTime(start.year, start.month + 1, 0);
      final end = monthEnd.isAfter(endToday) ? endToday : monthEnd;
      return (start: start, end: end);
    case BloodGlucosePeriod.year:
      final start = bloodGlucoseYearStart(yearStart ?? endToday);
      final yearEnd = DateTime(start.year, 12, 31);
      final end = yearEnd.isAfter(endToday) ? endToday : yearEnd;
      return (start: start, end: end);
    case BloodGlucosePeriod.all:
      if (earliestReadingAt == null) {
        return (start: endToday, end: endToday);
      }
      final start = bloodGlucoseLocalDateOnly(earliestReadingAt);
      if (start.isAfter(endToday)) {
        return (start: endToday, end: endToday);
      }
      return (start: start, end: endToday);
  }
}

String bloodGlucosePeriodLabel(
  BloodGlucosePeriod period, {
  DateTime? weekStart,
  DateTime? monthStart,
  DateTime? yearStart,
  DateTime? today,
}) {
  final now = bloodGlucoseLocalDateOnly(today ?? DateTime.now());
  switch (period) {
    case BloodGlucosePeriod.week:
      final start = bloodGlucoseWeekStart(weekStart ?? now);
      final thisWeek = bloodGlucoseWeekStart(now);
      if (start == thisWeek) {
        return 'This Week';
      }
      final end = DateTime(start.year, start.month, start.day + 6);
      return _formatWeekRangeLabel(start, end);
    case BloodGlucosePeriod.month:
      final start = bloodGlucoseMonthStart(monthStart ?? now);
      final thisMonth = bloodGlucoseMonthStart(now);
      if (start.year == thisMonth.year && start.month == thisMonth.month) {
        return 'This Month';
      }
      final month = _shortMonths[start.month - 1];
      if (start.year == now.year) {
        return month;
      }
      return '$month ${start.year}';
    case BloodGlucosePeriod.year:
      final start = bloodGlucoseYearStart(yearStart ?? now);
      if (start.year == now.year) {
        return 'This Year';
      }
      return '${start.year}';
    case BloodGlucosePeriod.all:
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

List<BloodGlucoseReading> bloodGlucoseReadingsInRange(
  List<BloodGlucoseReading> readings,
  DateTime start,
  DateTime end,
) {
  return [
    for (final reading in readings)
      if (!bloodGlucoseLocalDateOnly(reading.recordedAt).isBefore(start) &&
          !bloodGlucoseLocalDateOnly(reading.recordedAt).isAfter(end))
        reading,
  ];
}

/// One bucket per local day from [start] to [end]; value is latest reading that day.
List<BloodGlucoseChartDay> bloodGlucoseChartDays({
  required List<BloodGlucoseReading> readings,
  required DateTime start,
  required DateTime end,
}) {
  final rangeStart = bloodGlucoseLocalDateOnly(start);
  final rangeEnd = bloodGlucoseLocalDateOnly(end);

  final latestByDay = <DateTime, BloodGlucoseReading>{};
  for (final reading in readings) {
    final day = bloodGlucoseLocalDateOnly(reading.recordedAt);
    if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) {
      continue;
    }
    final existing = latestByDay[day];
    if (existing == null ||
        reading.recordedAt.isAfter(existing.recordedAt)) {
      latestByDay[day] = reading;
    }
  }

  final days = <BloodGlucoseChartDay>[];
  var cursor = rangeStart;
  while (!cursor.isAfter(rangeEnd)) {
    final day = bloodGlucoseLocalDateOnly(cursor);
    days.add(
      BloodGlucoseChartDay(
        day: day,
        valueMgDl: latestByDay[day]?.valueMgDl,
        axisLabel: _weekdayLetters[(day.weekday - 1) % 7],
      ),
    );
    cursor = DateTime(day.year, day.month, day.day + 1);
  }
  return days;
}

/// One bucket per calendar month from [start] to [end]; value is latest that month.
List<BloodGlucoseChartDay> bloodGlucoseChartMonths({
  required List<BloodGlucoseReading> readings,
  required DateTime start,
  required DateTime end,
}) {
  final rangeStart = bloodGlucoseMonthStart(start);
  final rangeEnd = bloodGlucoseLocalDateOnly(end);

  final latestByMonth = <DateTime, BloodGlucoseReading>{};
  for (final reading in readings) {
    final day = bloodGlucoseLocalDateOnly(reading.recordedAt);
    if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) {
      continue;
    }
    final month = bloodGlucoseMonthStart(day);
    final existing = latestByMonth[month];
    if (existing == null ||
        reading.recordedAt.isAfter(existing.recordedAt)) {
      latestByMonth[month] = reading;
    }
  }

  final months = <BloodGlucoseChartDay>[];
  var cursor = rangeStart;
  while (!cursor.isAfter(rangeEnd)) {
    final month = bloodGlucoseMonthStart(cursor);
    months.add(
      BloodGlucoseChartDay(
        day: month,
        valueMgDl: latestByMonth[month]?.valueMgDl,
        axisLabel: _monthLetters[month.month - 1],
      ),
    );
    cursor = DateTime(month.year, month.month + 1, 1);
  }
  return months;
}
