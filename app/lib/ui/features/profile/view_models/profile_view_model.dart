import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/patient_preferences.dart';
import 'package:flutter/material.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required AuthRepository authRepository,
    required PatientRepository patientRepository,
  })  : _authRepository = authRepository,
        _patientRepository = patientRepository {
    refresh();
  }

  final AuthRepository _authRepository;
  final PatientRepository _patientRepository;

  Patient? _patient;
  PatientPreferences? _preferences;
  String? _email;
  bool _isLoading = true;
  bool _isSigningOut = false;
  bool _isSaving = false;
  String? _errorMessage;

  Patient? get patient => _patient;
  PatientPreferences? get preferences => _preferences;
  String? get email => _email;
  bool get isLoading => _isLoading;
  bool get isSigningOut => _isSigningOut;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final authUserId = _authRepository.currentSession?.user.id;
    _email = _authRepository.currentSession?.user.email;

    if (authUserId == null) {
      _patient = null;
      _preferences = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _patient = await _patientRepository.getPatientForAuthUser(authUserId);
    _preferences = await _patientRepository.getOrCreatePreferencesForAuthUser(
      authUserId,
    );
    _isLoading = false;
    notifyListeners();
  }

  Patient _withPatient(
    Patient patient, {
    String? Function()? firstName,
    String? Function()? lastName,
    String? Function()? ckdStage,
    String? Function()? dialysisType,
    List<int>? Function()? dialysisDaysOfWeek,
    String? Function()? sex,
    DateTime? Function()? dateOfBirth,
    double? Function()? heightCm,
  }) {
    return Patient(
      id: patient.id,
      authUserId: patient.authUserId,
      firstName: firstName != null ? firstName() : patient.firstName,
      lastName: lastName != null ? lastName() : patient.lastName,
      dateOfBirth: dateOfBirth != null ? dateOfBirth() : patient.dateOfBirth,
      sex: sex != null ? sex() : patient.sex,
      ckdStage: ckdStage != null ? ckdStage() : patient.ckdStage,
      dialysisType:
          dialysisType != null ? dialysisType()! : patient.dialysisType,
      dialysisDaysOfWeek: dialysisDaysOfWeek != null
          ? dialysisDaysOfWeek()
          : patient.dialysisDaysOfWeek,
      heightCm: heightCm != null ? heightCm() : patient.heightCm,
      createdAt: patient.createdAt,
      updatedAt: patient.updatedAt,
      deletedAt: patient.deletedAt,
    );
  }

  Future<bool> updateName({
    required String? firstName,
    required String? lastName,
  }) {
    return _updatePatient(
      (patient) => _withPatient(
        patient,
        firstName: () => firstName,
        lastName: () => lastName,
      ),
    );
  }

  Future<bool> updateCkdStage(String? ckdStage) {
    return _updatePatient(
      (patient) => _withPatient(patient, ckdStage: () => ckdStage),
    );
  }

  Future<bool> updateDialysisType(String dialysisType) {
    return _updatePatient(
      (patient) => _withPatient(patient, dialysisType: () => dialysisType),
    );
  }

  Future<bool> updateDialysisDaysOfWeek(List<int>? dialysisDaysOfWeek) {
    return _updatePatient(
      (patient) => _withPatient(
        patient,
        dialysisDaysOfWeek: () => dialysisDaysOfWeek,
      ),
    );
  }

  Future<bool> updateSex(String? sex) {
    return _updatePatient(
      (patient) => _withPatient(patient, sex: () => sex),
    );
  }

  Future<bool> updateDateOfBirth(DateTime? dateOfBirth) {
    return _updatePatient(
      (patient) => _withPatient(patient, dateOfBirth: () => dateOfBirth),
    );
  }

  Future<bool> updateHeightCm(double? heightCm) {
    return _updatePatient(
      (patient) => _withPatient(patient, heightCm: () => heightCm),
    );
  }

  Future<bool> updateWeightUnit(String weightUnit) {
    return _updatePreferences(
      (prefs) => prefs.copyWith(weightUnit: weightUnit),
    );
  }

  Future<bool> updateBloodGlucoseUnit(String bloodGlucoseUnit) {
    return _updatePreferences(
      (prefs) => prefs.copyWith(bloodGlucoseUnit: bloodGlucoseUnit),
    );
  }

  Future<bool> updateDailyWaterGoalMl(int dailyWaterGoalMl) {
    return _updatePreferences(
      (prefs) => prefs.copyWith(dailyWaterGoalMl: dailyWaterGoalMl),
    );
  }

  Future<bool> _updatePatient(Patient Function(Patient current) build) async {
    final current = _patient;
    if (current == null || _isSaving) {
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = build(current);
      await _patientRepository.updateProfile(updated);
      _patient = updated;
      return true;
    } catch (error) {
      _errorMessage = 'Could not update profile. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> _updatePreferences(
    PatientPreferences Function(PatientPreferences current) build,
  ) async {
    final current = _preferences;
    if (current == null || _isSaving) {
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = build(current);
      await _patientRepository.updatePreferences(updated);
      _preferences = updated;
      return true;
    } catch (error) {
      _errorMessage = 'Could not update preferences. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_isSigningOut) {
      return;
    }
    _isSigningOut = true;
    notifyListeners();
    try {
      await _authRepository.signOut();
    } finally {
      _isSigningOut = false;
      notifyListeners();
    }
  }
}
