class BloodGlucoseReading {
  const BloodGlucoseReading({
    required this.id,
    required this.recordedAt,
    required this.valueMgDl,
    this.patientId,
    this.context,
    this.source = 'manual',
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? patientId;
  final DateTime recordedAt;
  final double valueMgDl;
  final String? context;
  final String source;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  String get displayValue => '${valueMgDl.toStringAsFixed(0)} mg/dL';
}
