import 'package:app/data/repositories/active_patient_notifier.dart';
import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/domain/models/accessible_patient.dart';
import 'package:app/domain/models/patient.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Patient list, active-patient switching and patient creation.
class PatientsViewModel extends ChangeNotifier {
  PatientsViewModel({
    required AuthRepository authRepository,
    required PatientRepository patientRepository,
    ActivePatientNotifier? activePatientNotifier,
  })  : _authRepository = authRepository,
        _patientRepository = patientRepository,
        _notifier = activePatientNotifier {
    _notifier?.addListener(_onActivePatientChanged);
    refresh();
  }

  final AuthRepository _authRepository;
  final PatientRepository _patientRepository;
  final ActivePatientNotifier? _notifier;

  List<AccessiblePatient> _patients = const [];
  String? _activePatientId;
  bool _isLoading = true;
  bool _isCreating = false;
  String? _errorMessage;
  bool _disposed = false;

  List<AccessiblePatient> get patients => _patients;
  String? get activePatientId => _activePatientId;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get errorMessage => _errorMessage;

  AccessiblePatient? get activePatient {
    for (final p in _patients) {
      if (p.patient.id == _activePatientId) {
        return p;
      }
    }
    return null;
  }

  /// True when the user is looking at someone else's record.
  bool get isViewingOther => activePatient != null && !activePatient!.isSelf;

  void _onActivePatientChanged() {
    refresh();
  }

  Future<void> refresh() async {
    final authUserId = _authRepository.currentSession?.user.id;
    if (authUserId == null) {
      _patients = const [];
      _activePatientId = null;
      _isLoading = false;
      _notify();
      return;
    }
    _patients = await _patientRepository.listAccessiblePatients(authUserId);
    _activePatientId =
        (await _patientRepository.getActivePatient(authUserId))?.id;
    _isLoading = false;
    _notify();
  }

  Future<void> switchTo(String patientId) async {
    if (patientId == _activePatientId) {
      return;
    }
    await _patientRepository.setActivePatient(patientId);
    // The notifier triggers refresh() for us (and for every other screen).
    if (_notifier == null) {
      await refresh();
    }
  }

  /// Returns the created patient, or null with [errorMessage] set.
  Future<Patient?> createPatient({
    required String firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? bloodGroup,
  }) async {
    if (_isCreating) {
      return null;
    }
    _isCreating = true;
    _errorMessage = null;
    _notify();
    try {
      final patient = await _patientRepository.createPatient(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        bloodGroup: bloodGroup,
      );
      if (_notifier == null) {
        await refresh();
      }
      return patient;
    } on PostgrestException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage =
          "Couldn't create the patient. Check your connection and try again.";
      return null;
    } finally {
      _isCreating = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _notifier?.removeListener(_onActivePatientChanged);
    super.dispose();
  }
}
