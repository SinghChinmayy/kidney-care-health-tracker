import 'package:app/data/repositories/sharing_repository.dart';
import 'package:app/domain/models/accessible_patient.dart';
import 'package:app/domain/models/patient_member.dart';
import 'package:app/domain/models/patient_role.dart';
import 'package:flutter/foundation.dart';

/// Who has access to one patient, and the owner's controls.
class PatientAccessViewModel extends ChangeNotifier {
  PatientAccessViewModel({
    required SharingRepository sharingRepository,
    required this.patient,
  }) : _sharing = sharingRepository;

  final SharingRepository _sharing;
  final AccessiblePatient patient;

  List<PatientMember> _members = const [];
  String? _myUsername;
  bool _isLoading = true;
  bool _isBusy = false;
  String? _loadError;
  bool _disposed = false;

  List<PatientMember> get members => _members;
  String? get myUsername => _myUsername;
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  String? get loadError => _loadError;
  String? get currentUserId => _sharing.currentUserId;

  bool get canManage => patient.role.canManageAccess;

  /// Owners can't leave while they are the only owner; the patient's own
  /// account can never leave its record.
  bool get canLeave {
    if (patient.isSelf) {
      return false;
    }
    if (patient.role != PatientRole.owner) {
      return true;
    }
    return _members.where((m) => m.role == PatientRole.owner).length > 1;
  }

  /// Owners may change/remove anyone except the patient's own account.
  bool canEditMember(PatientMember member) =>
      canManage && !member.isPatient && member.userId != currentUserId;

  Future<void> load() async {
    _isLoading = true;
    _loadError = null;
    _notify();
    try {
      final results = await Future.wait([
        _sharing.listMembers(patient.patient.id),
        _sharing.getMyUsername(),
      ]);
      _members = results[0] as List<PatientMember>;
      _myUsername = results[1] as String?;
    } on SharingException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = "Couldn't load access. Check your connection.";
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Returns an error message, or null on success.
  Future<String?> grant(String username, PatientRole role) {
    return _run(
      () => _sharing.grantAccess(
        patientId: patient.patient.id,
        username: username,
        role: role,
      ),
    );
  }

  Future<String?> changeRole(PatientMember member, PatientRole role) {
    return _run(
      () => _sharing.changeRole(
        patientId: patient.patient.id,
        userId: member.userId,
        role: role,
      ),
    );
  }

  Future<String?> remove(PatientMember member) {
    return _run(
      () => _sharing.revokeAccess(
        patientId: patient.patient.id,
        userId: member.userId,
      ),
    );
  }

  Future<String?> leave() {
    final me = currentUserId;
    if (me == null) {
      return Future.value('Sign in again to continue.');
    }
    return _run(
      () => _sharing.revokeAccess(patientId: patient.patient.id, userId: me),
      reload: false,
    );
  }

  Future<String?> _run(
    Future<void> Function() action, {
    bool reload = true,
  }) async {
    if (_isBusy) {
      return null;
    }
    _isBusy = true;
    _notify();
    try {
      await action();
      if (reload) {
        await load();
      }
      return null;
    } on SharingException catch (error) {
      return error.message;
    } catch (_) {
      return 'Something went wrong. Check your connection and try again.';
    } finally {
      _isBusy = false;
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
    super.dispose();
  }
}
