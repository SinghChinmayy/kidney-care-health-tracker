class WeightReading {
  const WeightReading({
    required this.id,
    required this.recordedAt,
    required this.valueKg,
    this.source = 'manual',
    this.notes,
  });

  final String id;
  final DateTime recordedAt;
  final double valueKg;
  final String source;
  final String? notes;

  String get displayValue => '${valueKg.toStringAsFixed(1)} kg';
}
