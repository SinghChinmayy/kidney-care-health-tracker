/// Parses Postgres/Supabase timestamptz values to UTC [DateTime].
DateTime parseRemoteDateTime(dynamic value) {
  if (value is DateTime) {
    return value.toUtc();
  }
  if (value is String) {
    return DateTime.parse(value).toUtc();
  }
  throw FormatException('Expected DateTime or ISO-8601 string, got $value');
}

DateTime? parseRemoteDateTimeOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  return parseRemoteDateTime(value);
}

DateTime? parseRemoteDateOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return DateTime.utc(value.year, value.month, value.day);
  }
  if (value is String) {
    final parsed = DateTime.parse(value);
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }
  throw FormatException('Expected date value, got $value');
}

/// Remote wins only when strictly newer; ties keep local (local wins on push).
bool shouldApplyRemoteUpdate({
  required DateTime remoteUpdatedAt,
  required DateTime localUpdatedAt,
}) {
  return remoteUpdatedAt.isAfter(localUpdatedAt);
}

String? remoteIsoDateTime(DateTime? value) {
  return value?.toUtc().toIso8601String();
}

String? remoteIsoDate(DateTime? value) {
  if (value == null) {
    return null;
  }
  final utc = value.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}';
}

double? parseRemoteDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

int? parseRemoteInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}
