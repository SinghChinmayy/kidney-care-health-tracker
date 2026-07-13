import 'package:app/domain/models/weight_reading.dart';

enum WeightPeriod {
  last7Days,
  last30Days,
  month,
}

class WeightChartDay {
  const WeightChartDay({
    required this.day,
    required this.axisLabel,
    this.valueKg,
  });

  final DateTime day;
  final double? valueKg;
  final String axisLabel;
}

DateTime weightLocalDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime weightMonthStart(DateTime day) {
  final local = weightLocalDateOnly(day);
  return DateTime(local.year, local.month, 1);
}

({DateTime start, DateTime end}) weightPeriodRange(
  WeightPeriod period,
  DateTime today, {
  DateTime? earliestReadingAt,
  DateTime? monthStart,
}) {
  final endToday = weightLocalDateOnly(today);
  switch (period) {
    case WeightPeriod.last7Days:
      final start = endToday.subtract(const Duration(days: 6));
      return (start: start, end: endToday);
    case WeightPeriod.last30Days:
      final start = endToday.subtract(const Duration(days: 29));
      return (start: start, end: endToday);
    case WeightPeriod.month:
      final start = weightMonthStart(monthStart ?? endToday);
      final monthEnd = DateTime(start.year, start.month + 1, 0);
      final end = monthEnd.isAfter(endToday) ? endToday : monthEnd;
      return (start: start, end: end);
  }
}

String weightPeriodLabel(
  WeightPeriod period, {
  DateTime? monthStart,
  DateTime? today,
}) {
  final now = weightLocalDateOnly(today ?? DateTime.now());
  switch (period) {
    case WeightPeriod.last7Days:
      return 'Last 7 Days';
    case WeightPeriod.last30Days:
      return 'Last 30 Days';
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

  final totalDays = rangeEnd.difference(rangeStart).inDays;
  final days = <WeightChartDay>[];
  var cursor = rangeStart;
  while (!cursor.isAfter(rangeEnd)) {
    final day = weightLocalDateOnly(cursor);
    final axisLabel = totalDays > 7
        ? '${day.day}'
        : _weekdayLetters[(day.weekday - 1) % 7];
    days.add(
      WeightChartDay(
        day: day,
        valueKg: latestByDay[day]?.valueKg,
        axisLabel: axisLabel,
      ),
    );
    cursor = DateTime(day.year, day.month, day.day + 1);
  }
  return days;
}
