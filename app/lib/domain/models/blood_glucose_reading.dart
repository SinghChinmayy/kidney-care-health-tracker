class BloodGlucoseReading {
  const BloodGlucoseReading({
    required this.id,
    required this.recordedAt,
    required this.valueMgDl,
    this.context,
    this.source = 'manual',
    this.notes,
  });

  final String id;
  final DateTime recordedAt;
  final double valueMgDl;
  final String? context;
  final String source;
  final String? notes;

  String get displayValue => '${valueMgDl.toStringAsFixed(0)} mg/dL';
}
