class PatientMedicationSchedule {
  const PatientMedicationSchedule({
    required this.id,
    required this.patientId,
    this.byDay = const {},
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String patientId;

  /// ISO weekday 1=Mon … 7=Sun → ordered catalog medication ids.
  final Map<int, List<String>> byDay;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  List<String> medIdsForDay(int isoWeekday) =>
      List<String>.from(byDay[isoWeekday] ?? const []);

  bool get hasAnyMeds => byDay.values.any((ids) => ids.isNotEmpty);

  PatientMedicationSchedule copyWith({
    String? id,
    String? patientId,
    Map<int, List<String>>? byDay,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return PatientMedicationSchedule(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      byDay: byDay ?? this.byDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
