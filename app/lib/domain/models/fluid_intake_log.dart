class FluidIntakeLog {
  const FluidIntakeLog({
    required this.id,
    required this.recordedAt,
    required this.fluidMl,
    this.patientId,
    this.source = 'manual',
    this.recordedBy,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? patientId;
  final DateTime recordedAt;
  final double fluidMl;
  final String source;

  /// auth user id of whoever logged it; null = unknown.
  final String? recordedBy;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  String get displayValue {
    final ml = fluidMl;
    if (ml == ml.roundToDouble()) {
      return '${ml.toStringAsFixed(0)} ml';
    }
    return '${ml.toStringAsFixed(1)} ml';
  }
}
