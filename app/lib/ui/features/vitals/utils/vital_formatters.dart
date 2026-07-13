import 'package:app/domain/models/weight_reading_options.dart';

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

String formatHomeDateLabel(DateTime localDate) {
  final weekday = _shortWeekdays[localDate.weekday - 1];
  final month = _shortMonths[localDate.month - 1];
  return '$weekday, $month ${localDate.day}';
}

DateTime recordedAtFromSelectedDate(DateTime selectedLocalDate) {
  final now = DateTime.now();
  return DateTime(
    selectedLocalDate.year,
    selectedLocalDate.month,
    selectedLocalDate.day,
    now.hour,
    now.minute,
    now.second,
    now.millisecond,
    now.microsecond,
  );
}

T? latestReadingOnLocalDate<T>(
  List<T> readings,
  DateTime localDate,
  DateTime Function(T reading) recordedAt,
) {
  T? latest;
  for (final reading in readings) {
    if (localDateOnly(recordedAt(reading)) != localDate) {
      continue;
    }
    if (latest == null || recordedAt(reading).isAfter(recordedAt(latest))) {
      latest = reading;
    }
  }
  return latest;
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

String formatDialysisTimingLabel(String dialysisTiming) {
  return switch (dialysisTiming) {
    'pre_dialysis' => 'Pre-dialysis',
    'post_dialysis' => 'Post-dialysis',
    _ => 'Non-dialysis day',
  };
}

/// Short labels for compact hero/summary captions.
String formatCompactDialysisTimingLabel(String dialysisTiming) {
  return switch (dialysisTiming) {
    'pre_dialysis' => 'Pre',
    'post_dialysis' => 'Post',
    _ => 'Off',
  };
}

String formatWeightContextLabel(String context) {
  return switch (context) {
    weightContextMorning => 'Morning',
    weightContextEvening => 'Evening',
    weightContextRandom => 'Random',
    _ => context.replaceAll('_', ' '),
  };
}

String formatCompactWeightContextLabel(String context) {
  return switch (context) {
    weightContextMorning => 'AM',
    weightContextEvening => 'PM',
    weightContextRandom => 'Rand',
    _ => context.replaceAll('_', ' '),
  };
}

String formatWeightHistorySubtitle({
  required String dialysisTiming,
  required DateTime recordedAt,
  String? weightContext,
}) {
  final parts = <String>[
    formatDialysisTimingLabel(dialysisTiming),
    formatHistoryTime(recordedAt),
  ];
  if (weightContext != null && weightContext.isNotEmpty) {
    parts.add(formatWeightContextLabel(weightContext));
  }
  return parts.join(' · ');
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

/// Compact caption for weight-gain hero nodes (e.g. `Mon 8` / `Today · 09:00`).
String formatWeightNodeCaption(DateTime recordedAt, {bool includeTime = false}) {
  final local = recordedAt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  final weekday = _shortWeekdays[local.weekday - 1];

  if (date == today) {
    return includeTime ? 'Today · ${formatHistoryTime(recordedAt)}' : 'Today';
  }

  final dayLabel = '$weekday ${local.day}';
  if (!includeTime) return dayLabel;
  return '$dayLabel · ${formatHistoryTime(recordedAt)}';
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

/// Monday (local) of the week that contains [localDate].
DateTime weekStartForLocalDate(DateTime localDate) {
  final date = localDateOnly(localDate);
  return date.subtract(Duration(days: date.weekday - 1));
}

String formatWeekGroupLabel(DateTime weekStart) {
  final today = localDateOnly(DateTime.now());
  final thisWeekStart = weekStartForLocalDate(today);
  if (weekStart == thisWeekStart) {
    return 'This Week';
  }

  final lastWeekStart = DateTime(
    thisWeekStart.year,
    thisWeekStart.month,
    thisWeekStart.day - 7,
  );
  if (weekStart == lastWeekStart) {
    return 'Last Week';
  }

  final weekEnd = DateTime(
    weekStart.year,
    weekStart.month,
    weekStart.day + 6,
  );
  return _formatWeekRangeLabel(weekStart, weekEnd);
}

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

Map<DateTime, List<T>> groupReadingsByWeekStart<T>(
  List<T> readings,
  DateTime Function(T reading) recordedAt,
) {
  final grouped = <DateTime, List<T>>{};

  for (final reading in readings) {
    final weekKey = weekStartForLocalDate(recordedAt(reading));
    grouped.putIfAbsent(weekKey, () => []).add(reading);
  }

  final sortedKeys = grouped.keys.toList()
    ..sort((a, b) => b.compareTo(a));

  return {for (final key in sortedKeys) key: grouped[key]!};
}
