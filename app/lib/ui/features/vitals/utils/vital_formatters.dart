const _shortWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

const _weekdays = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];

const _months = [
  'JANUARY',
  'FEBRUARY',
  'MARCH',
  'APRIL',
  'MAY',
  'JUNE',
  'JULY',
  'AUGUST',
  'SEPTEMBER',
  'OCTOBER',
  'NOVEMBER',
  'DECEMBER',
];

DateTime localDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

String formatHistoryDateHeader(DateTime localDate) {
  final weekday = _weekdays[localDate.weekday - 1];
  final month = _months[localDate.month - 1];
  return '$weekday, $month ${localDate.day}';
}

String formatHistoryTime(DateTime recordedAt) {
  final local = recordedAt.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatTrackRecordedAt(DateTime recordedAt) {
  final local = recordedAt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  final time = formatHistoryTime(recordedAt);

  if (date == today) {
    return 'Today · $time';
  }

  final weekday = _shortWeekdays[local.weekday - 1];
  final month = _shortMonths[local.month - 1];
  if (local.year == now.year) {
    return '$weekday, $month ${local.day} · $time';
  }

  return '$weekday, $month ${local.day}, ${local.year} · $time';
}

Map<DateTime, List<T>> groupReadingsByLocalDate<T>(
  List<T> readings,
  DateTime Function(T reading) recordedAt,
) {
  final grouped = <DateTime, List<T>>{};

  for (final reading in readings) {
    final dateKey = localDateOnly(recordedAt(reading));
    grouped.putIfAbsent(dateKey, () => []).add(reading);
  }

  final sortedKeys = grouped.keys.toList()
    ..sort((a, b) => b.compareTo(a));

  return {for (final key in sortedKeys) key: grouped[key]!};
}
