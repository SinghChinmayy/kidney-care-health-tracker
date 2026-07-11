import 'dart:convert';

import 'package:drift/drift.dart';

/// Stores ISO weekday ints (1=Mon … 7=Sun) as a JSON array string in SQLite.
class DialysisDaysOfWeekConverter extends TypeConverter<List<int>, String> {
  const DialysisDaysOfWeekConverter();

  @override
  List<int> fromSql(String fromDb) {
    return parseDialysisDaysList(jsonDecode(fromDb));
  }

  @override
  String toSql(List<int> value) {
    return jsonEncode(value);
  }
}

/// Parses remote jsonb / dynamic JSON into sorted unique ISO weekday ints.
List<int>? parseDialysisDaysOfWeek(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    if (value.isEmpty) {
      return null;
    }
    return parseDialysisDaysList(jsonDecode(value));
  }
  return parseDialysisDaysList(value);
}

List<int> parseDialysisDaysList(Object? decoded) {
  if (decoded is! List) {
    return const [];
  }
  final days = <int>[];
  for (final item in decoded) {
    final day = switch (item) {
      int value => value,
      num value => value.toInt(),
      _ => null,
    };
    if (day == null || day < 1 || day > 7 || days.contains(day)) {
      continue;
    }
    days.add(day);
  }
  days.sort();
  return days;
}
