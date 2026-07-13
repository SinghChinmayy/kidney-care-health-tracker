import 'package:app/domain/models/patient_preferences.dart';

/// Profile + preference values collected during patient signup.
class PatientSignupProfile {
  const PatientSignupProfile({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.sex,
    required this.ckdStage,
    required this.dialysisType,
    this.dialysisDaysOfWeek,
    this.heightCm,
    this.weightUnit = PatientPreferences.defaultWeightUnit,
    this.bloodGlucoseUnit = PatientPreferences.defaultBloodGlucoseUnit,
    this.dailyWaterGoalMl = PatientPreferences.defaultDailyWaterGoalMl,
  });

  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String sex;
  final String ckdStage;
  final String dialysisType;
  final List<int>? dialysisDaysOfWeek;
  final double? heightCm;
  final String weightUnit;
  final String bloodGlucoseUnit;
  final int dailyWaterGoalMl;
}
