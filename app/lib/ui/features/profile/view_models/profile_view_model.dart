import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/domain/errors/profile_update_requires_network.dart';
import 'package:app/domain/models/patient.dart';
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
  String? _email;
  bool _isLoading = true;
  bool _isSigningOut = false;
  bool _isSaving = false;
  String? _errorMessage;

  Patient? get patient => _patient;
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
      _isLoading = false;
      notifyListeners();
      return;
    }

    _patient = await _patientRepository.getPatientForAuthUser(authUserId);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateCkdStage(String? ckdStage) {
    return _updatePatient((patient) => Patient(
          id: patient.id,
          authUserId: patient.authUserId,
          firstName: patient.firstName,
          lastName: patient.lastName,
          dateOfBirth: patient.dateOfBirth,
          sex: patient.sex,
          ckdStage: ckdStage,
          dialysisType: patient.dialysisType,
          heightCm: patient.heightCm,
          createdAt: patient.createdAt,
          updatedAt: patient.updatedAt,
          deletedAt: patient.deletedAt,
        ));
  }

  Future<bool> updateDialysisType(String dialysisType) {
    return _updatePatient((patient) => Patient(
          id: patient.id,
          authUserId: patient.authUserId,
          firstName: patient.firstName,
          lastName: patient.lastName,
          dateOfBirth: patient.dateOfBirth,
          sex: patient.sex,
          ckdStage: patient.ckdStage,
          dialysisType: dialysisType,
          heightCm: patient.heightCm,
          createdAt: patient.createdAt,
          updatedAt: patient.updatedAt,
          deletedAt: patient.deletedAt,
        ));
  }

  Future<bool> updateSex(String? sex) {
    return _updatePatient((patient) => Patient(
          id: patient.id,
          authUserId: patient.authUserId,
          firstName: patient.firstName,
          lastName: patient.lastName,
          dateOfBirth: patient.dateOfBirth,
          sex: sex,
          ckdStage: patient.ckdStage,
          dialysisType: patient.dialysisType,
          heightCm: patient.heightCm,
          createdAt: patient.createdAt,
          updatedAt: patient.updatedAt,
          deletedAt: patient.deletedAt,
        ));
  }

  Future<bool> updateDateOfBirth(DateTime? dateOfBirth) {
    return _updatePatient((patient) => Patient(
          id: patient.id,
          authUserId: patient.authUserId,
          firstName: patient.firstName,
          lastName: patient.lastName,
          dateOfBirth: dateOfBirth,
          sex: patient.sex,
          ckdStage: patient.ckdStage,
          dialysisType: patient.dialysisType,
          heightCm: patient.heightCm,
          createdAt: patient.createdAt,
          updatedAt: patient.updatedAt,
          deletedAt: patient.deletedAt,
        ));
  }

  Future<bool> updateHeightCm(double? heightCm) {
    return _updatePatient((patient) => Patient(
          id: patient.id,
          authUserId: patient.authUserId,
          firstName: patient.firstName,
          lastName: patient.lastName,
          dateOfBirth: patient.dateOfBirth,
          sex: patient.sex,
          ckdStage: patient.ckdStage,
          dialysisType: patient.dialysisType,
          heightCm: heightCm,
          createdAt: patient.createdAt,
          updatedAt: patient.updatedAt,
          deletedAt: patient.deletedAt,
        ));
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
    } on ProfileUpdateRequiresNetworkException catch (error) {
      _errorMessage = error.toString();
      return false;
    } catch (error) {
      _errorMessage = 'Could not update profile. Please try again.';
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
