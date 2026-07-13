import 'package:app/domain/models/blood_glucose_reading.dart';

enum BloodGlucosePeriod {
  last7Days,
  last30Days,
  month,
}

class BloodGlucoseChartDay {
  const BloodGlucoseChartDay({
    required this.day,
    required this.axisLabel,
    this.valueMgDl,
  });

  final DateTime day;
  final double? valueMgDl;
  final String axisLabel;
}

DateTime bloodGlucoseLocalDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime bloodGlucoseMonthStart(DateTime day) {
  final local = bloodGlucoseLocalDateOnly(day);
  return DateTime(local.year, local.month, 1);
}

({DateTime start, DateTime end}) bloodGlucosePeriodRange(
  BloodGlucosePeriod period,
  DateTime today, {
  DateTime? earliestReadingAt,
  DateTime? monthStart,
}) {
  final endToday = bloodGlucoseLocalDateOnly(today);
  switch (period) {
    case BloodGlucosePeriod.last7Days:
      final start = endToday.subtract(const Duration(days: 6));
      return (start: start, end: endToday);
    case BloodGlucosePeriod.last30Days:
      final start = endToday.subtract(const Duration(days: 29));
      return (start: start, end: endToday);
    case BloodGlucosePeriod.month:
      final start = bloodGlucoseMonthStart(monthStart ?? endToday);
      final monthEnd = DateTime(start.year, start.month + 1, 0);
      final end = monthEnd.isAfter(endToday) ? endToday : monthEnd;
      return (start: start, end: end);
  }
}

String bloodGlucosePeriodLabel(
  BloodGlucosePeriod period, {
  DateTime? monthStart,
  DateTime? today,
}) {
  final now = bloodGlucoseLocalDateOnly(today ?? DateTime.now());
  switch (period) {
    case BloodGlucosePeriod.last7Days:
      return 'Last 7 Days';
    case BloodGlucosePeriod.last30Days:
      return 'Last 30 Days';
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

  final totalDays = rangeEnd.difference(rangeStart).inDays;
  final days = <BloodGlucoseChartDay>[];
  var cursor = rangeStart;
  while (!cursor.isAfter(rangeEnd)) {
    final day = bloodGlucoseLocalDateOnly(cursor);
    final axisLabel = totalDays > 7
        ? '${day.day}'
        : _weekdayLetters[(day.weekday - 1) % 7];
    days.add(
      BloodGlucoseChartDay(
        day: day,
        valueMgDl: latestByDay[day]?.valueMgDl,
        axisLabel: axisLabel,
      ),
    );
    cursor = DateTime(day.year, day.month, day.day + 1);
  }
  return days;
}
