import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/sync/sync_coordinator.dart';
import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/patient_signup_profile.dart';
import 'package:app/domain/models/sign_up_result.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientSignupViewModel extends ChangeNotifier {
  PatientSignupViewModel({
    required AuthRepository authRepository,
    required PatientRepository patientRepository,
    required SyncCoordinator syncCoordinator,
  })  : _authRepository = authRepository,
        _patientRepository = patientRepository,
        _syncCoordinator = syncCoordinator;

  final AuthRepository _authRepository;
  final PatientRepository _patientRepository;
  final SyncCoordinator _syncCoordinator;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  String? get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<SignUpResult?> signUp({
    required String email,
    required String password,
    required PatientSignupProfile profile,
  }) async {
    if (_isLoading) {
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.signUp(
        email: email,
        password: password,
      );

      if (result.hasSession) {
        await _applyProfile(profile);
      }

      return result;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Sign up failed. Please try again.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _applyProfile(PatientSignupProfile profile) async {
    final authUserId = _authRepository.currentSession?.user.id;
    if (authUserId == null) {
      return;
    }

    // Pull the server-bootstrapped patients row before writing profile fields.
    await _syncCoordinator.run();

    final patient = await _patientRepository.getPatientForAuthUser(authUserId);
    if (patient == null) {
      return;
    }

    await _patientRepository.updateProfile(
      Patient(
        id: patient.id,
        authUserId: patient.authUserId,
        firstName: profile.firstName,
        lastName: profile.lastName,
        dateOfBirth: profile.dateOfBirth,
        sex: profile.sex,
        ckdStage: profile.ckdStage,
        dialysisType: profile.dialysisType,
        dialysisDaysOfWeek: profile.dialysisType == 'none'
            ? null
            : profile.dialysisDaysOfWeek,
        heightCm: profile.heightCm,
        createdAt: patient.createdAt,
        updatedAt: patient.updatedAt,
        deletedAt: patient.deletedAt,
      ),
    );

    final preferences =
        await _patientRepository.getOrCreatePreferencesForAuthUser(authUserId);
    if (preferences == null) {
      return;
    }

    await _patientRepository.updatePreferences(
      preferences.copyWith(
        weightUnit: profile.weightUnit,
        bloodGlucoseUnit: profile.bloodGlucoseUnit,
        dailyWaterGoalMl: profile.dailyWaterGoalMl,
      ),
    );
  }
}
