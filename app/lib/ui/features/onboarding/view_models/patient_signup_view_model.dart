import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/domain/models/sign_up_result.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientSignupViewModel extends ChangeNotifier {
  PatientSignupViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<SignUpResult?> signUp({
    required String email,
    required String password,
  }) async {
    if (_isLoading) {
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _authRepository.signUp(
        email: email,
        password: password,
      );
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
}
