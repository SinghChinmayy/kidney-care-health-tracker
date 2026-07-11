class PatientPreferences {
  const PatientPreferences({
    required this.id,
    required this.patientId,
    this.weightUnit = defaultWeightUnit,
    this.bloodGlucoseUnit = defaultBloodGlucoseUnit,
    this.dailyWaterGoalMl = defaultDailyWaterGoalMl,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  static const defaultWeightUnit = 'kg';
  static const defaultBloodGlucoseUnit = 'mg_dl';
  static const defaultDailyWaterGoalMl = 1200;

  final String id;
  final String patientId;
  final String weightUnit;
  final String bloodGlucoseUnit;
  final int dailyWaterGoalMl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  PatientPreferences copyWith({
    String? id,
    String? patientId,
    String? weightUnit,
    String? bloodGlucoseUnit,
    int? dailyWaterGoalMl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return PatientPreferences(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      weightUnit: weightUnit ?? this.weightUnit,
      bloodGlucoseUnit: bloodGlucoseUnit ?? this.bloodGlucoseUnit,
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

const weightUnitOptions = ['kg', 'lb'];

const bloodGlucoseUnitOptions = ['mg_dl', 'mmol_l'];
