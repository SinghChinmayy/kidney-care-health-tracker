import 'package:app/domain/models/blood_pressure_reading.dart';

enum BloodPressurePeriod {
  last7Days,
  last30Days,
  month,
}

class BloodPressureChartDay {
  const BloodPressureChartDay({
    required this.day,
    required this.axisLabel,
    this.systolic,
    this.diastolic,
    this.heartRateBpm,
  });

  /// Local calendar day (or month start for monthly buckets).
  final DateTime day;
  final int? systolic;
  final int? diastolic;
  final int? heartRateBpm;

  /// X-axis tick label (weekday letter or month initial).
  final String axisLabel;
}

DateTime bloodPressureLocalDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// First day of the calendar month that contains [day].
DateTime bloodPressureMonthStart(DateTime day) {
  final local = bloodPressureLocalDateOnly(day);
  return DateTime(local.year, local.month, 1);
}

/// Inclusive local-date range for [period].
({DateTime start, DateTime end}) bloodPressurePeriodRange(
  BloodPressurePeriod period,
  DateTime today, {
  DateTime? earliestReadingAt,
  DateTime? monthStart,
}) {
  final endToday = bloodPressureLocalDateOnly(today);
  switch (period) {
    case BloodPressurePeriod.last7Days:
      final start = endToday.subtract(const Duration(days: 6));
      return (start: start, end: endToday);
    case BloodPressurePeriod.last30Days:
      final start = endToday.subtract(const Duration(days: 29));
      return (start: start, end: endToday);
    case BloodPressurePeriod.month:
      final start = bloodPressureMonthStart(monthStart ?? endToday);
      final monthEnd = DateTime(start.year, start.month + 1, 0);
      final end = monthEnd.isAfter(endToday) ? endToday : monthEnd;
      return (start: start, end: end);
  }
}

String bloodPressurePeriodLabel(
  BloodPressurePeriod period, {
  DateTime? monthStart,
  DateTime? today,
}) {
  final now = bloodPressureLocalDateOnly(today ?? DateTime.now());
  switch (period) {
    case BloodPressurePeriod.last7Days:
      return 'Last 7 Days';
    case BloodPressurePeriod.last30Days:
      return 'Last 30 Days';
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

/// One bucket per local day from [start] to [end]; value is latest systolic/diastolic/HR that day.
List<BloodPressureChartDay> bloodPressureChartDays({
  required List<BloodPressureReading> readings,
  required DateTime start,
  required DateTime end,
}) {
  final rangeStart = bloodPressureLocalDateOnly(start);
  final rangeEnd = bloodPressureLocalDateOnly(end);

  final latestByDay = <DateTime, BloodPressureReading>{};
  for (final reading in readings) {
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
    final reading = latestByDay[day];
    
    // For 30D / Month, showing full weekday letters can be crowded or we can format labels as day numbers (e.g. "13").
    // Let's make axisLabel represent the day of month if the range is greater than 7 days, else weekday.
    final totalDays = rangeEnd.difference(rangeStart).inDays;
    final String axisLabel = totalDays > 7 
        ? '${day.day}' 
        : _weekdayLetters[(day.weekday - 1) % 7];

    days.add(
      BloodPressureChartDay(
        day: day,
        systolic: reading?.systolic,
        diastolic: reading?.diastolic,
        heartRateBpm: reading?.heartRateBpm,
        axisLabel: axisLabel,
      ),
    );
    cursor = DateTime(day.year, day.month, day.day + 1);
  }
  return days;
}
