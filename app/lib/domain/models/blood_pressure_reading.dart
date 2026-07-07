class BloodPressureReading {
  const BloodPressureReading({
    required this.id,
    required this.recordedAt,
    this.patientId,
    this.systolic,
    this.diastolic,
    this.heartRateBpm,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? patientId;
  final DateTime recordedAt;
  final int? systolic;
  final int? diastolic;
  final int? heartRateBpm;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

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
