import 'package:app/domain/models/blood_pressure_reading.dart';

enum BloodPressurePeriod {
  week,
  month,
  year,
  all,
}

class BloodPressureChartDay {
  const BloodPressureChartDay({
    required this.day,
    required this.axisLabel,
    this.systolic,
  });

  /// Local calendar day (or month start for monthly buckets).
  final DateTime day;
  final int? systolic;

  /// X-axis tick label (weekday letter or month initial).
  final String axisLabel;
}

DateTime bloodPressureLocalDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Monday (local) of the week that contains [day].
DateTime bloodPressureWeekStart(DateTime day) {
  final local = bloodPressureLocalDateOnly(day);
  return local.subtract(Duration(days: local.weekday - 1));
}

/// First day of the calendar month that contains [day].
DateTime bloodPressureMonthStart(DateTime day) {
  final local = bloodPressureLocalDateOnly(day);
  return DateTime(local.year, local.month, 1);
}

/// January 1 of the calendar year that contains [day].
DateTime bloodPressureYearStart(DateTime day) {
  final local = bloodPressureLocalDateOnly(day);
  return DateTime(local.year, 1, 1);
}

/// Inclusive local-date range for [period].
({DateTime start, DateTime end}) bloodPressurePeriodRange(
  BloodPressurePeriod period,
  DateTime today, {
  DateTime? earliestReadingAt,
  DateTime? weekStart,
  DateTime? monthStart,
  DateTime? yearStart,
}) {
  final endToday = bloodPressureLocalDateOnly(today);
  switch (period) {
    case BloodPressurePeriod.week:
      final start = bloodPressureWeekStart(weekStart ?? endToday);
      final weekEnd = DateTime(start.year, start.month, start.day + 6);
      final end = weekEnd.isAfter(endToday) ? endToday : weekEnd;
      return (start: start, end: end);
    case BloodPressurePeriod.month:
      final start = bloodPressureMonthStart(monthStart ?? endToday);
      final monthEnd = DateTime(start.year, start.month + 1, 0);
      final end = monthEnd.isAfter(endToday) ? endToday : monthEnd;
      return (start: start, end: end);
    case BloodPressurePeriod.year:
      final start = bloodPressureYearStart(yearStart ?? endToday);
      final yearEnd = DateTime(start.year, 12, 31);
      final end = yearEnd.isAfter(endToday) ? endToday : yearEnd;
      return (start: start, end: end);
    case BloodPressurePeriod.all:
      if (earliestReadingAt == null) {
        return (start: endToday, end: endToday);
      }
      final start = bloodPressureLocalDateOnly(earliestReadingAt);
      if (start.isAfter(endToday)) {
        return (start: endToday, end: endToday);
      }
      return (start: start, end: endToday);
  }
}

String bloodPressurePeriodLabel(
  BloodPressurePeriod period, {
  DateTime? weekStart,
  DateTime? monthStart,
  DateTime? yearStart,
  DateTime? today,
}) {
  final now = bloodPressureLocalDateOnly(today ?? DateTime.now());
  switch (period) {
    case BloodPressurePeriod.week:
      final start = bloodPressureWeekStart(weekStart ?? now);
      final thisWeek = bloodPressureWeekStart(now);
      if (start == thisWeek) {
        return 'This Week';
      }
      final end = DateTime(start.year, start.month, start.day + 6);
      return _formatWeekRangeLabel(start, end);
    case BloodPressurePeriod.month:
      final start = bloodPressureMonthStart(monthStart ?? now);
      final thisMonth = bloodPressureMonthStart(now);
      if (start.year == thisMonth.year && start.month == thisMonth.month) {
        return 'This Month';
      }
      final month = _shortMonths[start.month - 1];
      if (start.year == now.year) {
        return month;
      }
      return '$month ${start.year}';
    case BloodPressurePeriod.year:
      final start = bloodPressureYearStart(yearStart ?? now);
      if (start.year == now.year) {
        return 'This Year';
      }
      return '${start.year}';
    case BloodPressurePeriod.all:
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

List<BloodPressureReading> bloodPressureReadingsInRange(
  List<BloodPressureReading> readings,
  DateTime start,
  DateTime end,
) {
  return [
    for (final reading in readings)
      if (!bloodPressureLocalDateOnly(reading.recordedAt).isBefore(start) &&
          !bloodPressureLocalDateOnly(reading.recordedAt).isAfter(end))
        reading,
  ];
}

/// One bucket per local day from [start] to [end]; value is latest systolic that day.
List<BloodPressureChartDay> bloodPressureChartDays({
  required List<BloodPressureReading> readings,
  required DateTime start,
  required DateTime end,
}) {
  final rangeStart = bloodPressureLocalDateOnly(start);
  final rangeEnd = bloodPressureLocalDateOnly(end);

  final latestByDay = <DateTime, BloodPressureReading>{};
  for (final reading in readings) {
    if (reading.systolic == null) {
      continue;
    }
    final day = bloodPressureLocalDateOnly(reading.recordedAt);
    if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) {
      continue;
    }
    final existing = latestByDay[day];
    if (existing == null ||
        reading.recordedAt.isAfter(existing.recordedAt)) {
      latestByDay[day] = reading;
    }
  }

  final days = <BloodPressureChartDay>[];
  var cursor = rangeStart;
  while (!cursor.isAfter(rangeEnd)) {
    final day = bloodPressureLocalDateOnly(cursor);
    days.add(
      BloodPressureChartDay(
        day: day,
        systolic: latestByDay[day]?.systolic,
        axisLabel: _weekdayLetters[(day.weekday - 1) % 7],
      ),
    );
    cursor = DateTime(day.year, day.month, day.day + 1);
  }
  return days;
}

/// One bucket per calendar month from [start] to [end]; value is latest systolic that month.
List<BloodPressureChartDay> bloodPressureChartMonths({
  required List<BloodPressureReading> readings,
  required DateTime start,
  required DateTime end,
}) {
  final rangeStart = bloodPressureMonthStart(start);
  final rangeEnd = bloodPressureLocalDateOnly(end);

  final latestByMonth = <DateTime, BloodPressureReading>{};
  for (final reading in readings) {
    if (reading.systolic == null) {
      continue;
    }
    final day = bloodPressureLocalDateOnly(reading.recordedAt);
    if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) {
      continue;
    }
    final month = bloodPressureMonthStart(day);
    final existing = latestByMonth[month];
    if (existing == null ||
        reading.recordedAt.isAfter(existing.recordedAt)) {
      latestByMonth[month] = reading;
    }
  }

  final months = <BloodPressureChartDay>[];
  var cursor = rangeStart;
  while (!cursor.isAfter(rangeEnd)) {
    final month = bloodPressureMonthStart(cursor);
    months.add(
      BloodPressureChartDay(
        day: month,
        systolic: latestByMonth[month]?.systolic,
        axisLabel: _monthLetters[month.month - 1],
      ),
    );
    cursor = DateTime(month.year, month.month + 1, 1);
  }
  return months;
}
