import 'dart:convert';

import 'package:drift/drift.dart';

/// `{ "by_day": { "1": ["med-id", ...], ... } }` stored as JSON text in SQLite.
class MedicationScheduleConverter
    extends TypeConverter<Map<int, List<String>>, String> {
  const MedicationScheduleConverter();

  @override
  Map<int, List<String>> fromSql(String fromDb) {
    return parseMedicationScheduleByDay(jsonDecode(fromDb));
  }

  @override
  String toSql(Map<int, List<String>> value) {
    return jsonEncode(medicationScheduleToJson(value));
  }
}

Map<String, dynamic> medicationScheduleToJson(Map<int, List<String>> byDay) {
  final byDayJson = <String, List<String>>{};
  final keys = byDay.keys.toList()..sort();
  for (final day in keys) {
    byDayJson['$day'] = List<String>.from(byDay[day] ?? const []);
  }
  return {'by_day': byDayJson};
}

Map<int, List<String>> parseMedicationScheduleByDay(Object? decoded) {
  if (decoded is! Map) {
    return {};
  }
  final rawByDay = decoded['by_day'];
  if (rawByDay is! Map) {
    return {};
  }
  final result = <int, List<String>>{};
  for (final entry in rawByDay.entries) {
    final day = int.tryParse(entry.key.toString());
    if (day == null || day < 1 || day > 7) {
      continue;
    }
    final ids = <String>[];
    final value = entry.value;
    if (value is List) {
      for (final item in value) {
        final id = item?.toString();
        if (id == null || id.isEmpty || ids.contains(id)) {
          continue;
        }
        ids.add(id);
      }
    }
    result[day] = ids;
  }
  return result;
}

/// Parse remote jsonb / dynamic JSON into by_day map.
Map<int, List<String>> parseMedicationSchedule(Object? value) {
  if (value == null) {
    return {};
  }
  if (value is String) {
    if (value.isEmpty) {
      return {};
    }
    return parseMedicationScheduleByDay(jsonDecode(value));
  }
  return parseMedicationScheduleByDay(value);
}
