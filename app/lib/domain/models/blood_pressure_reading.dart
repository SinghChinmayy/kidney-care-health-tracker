class BloodPressureReading {
  const BloodPressureReading({
    required this.id,
    required this.recordedAt,
    this.systolic,
    this.diastolic,
    this.heartRateBpm,
    this.notes,
  });

  final String id;
  final DateTime recordedAt;
  final int? systolic;
  final int? diastolic;
  final int? heartRateBpm;
  final String? notes;

  String get displayValue {
    final parts = <String>[];
    if (systolic != null && diastolic != null) {
      parts.add('$systolic/$diastolic mmHg');
    }
    if (heartRateBpm != null) {
      parts.add('$heartRateBpm bpm');
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}
