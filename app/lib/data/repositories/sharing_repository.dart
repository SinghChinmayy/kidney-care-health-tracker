import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/active_patient_notifier.dart';
import 'package:app/data/services/patient_access_remote.dart';
import 'package:app/domain/models/patient_member.dart';
import 'package:app/domain/models/patient_role.dart';

/// Usernames and per-patient sharing. Online-only: every call goes to a
/// SECURITY DEFINER RPC that re-checks the caller's role server-side.
class SharingRepository {
  SharingRepository({
    required AppDatabase db,
    required PatientAccessRemote remote,
    required String? Function() currentAuthUserId,
    ActivePatientNotifier? activePatientNotifier,
    void Function()? requestSync,
  })  : _db = db,
        _remote = remote,
        _currentAuthUserId = currentAuthUserId,
        _notifier = activePatientNotifier,
        _requestSync = requestSync ?? (() {});

  final AppDatabase _db;
  final PatientAccessRemote _remote;
  final String? Function() _currentAuthUserId;
  final ActivePatientNotifier? _notifier;
  final void Function() _requestSync;

  final Map<String, List<PatientMember>> _membersCache = {};

  String _requireUser() {
    final userId = _currentAuthUserId();
    if (userId == null) {
      throw const SharingException('Sign in again to continue.');
    }
    return userId;
  }

  String? get currentUserId => _currentAuthUserId();

  Future<String?> getMyUsername() => _remote.getMyUsername(_requireUser());

  Future<void> setMyUsername(String username) {
    return _remote.setMyUsername(_requireUser(), normalizeUsername(username));
  }

  Future<List<PatientMember>> listMembers(String patientId) async {
    final members = await _remote.listMembers(patientId);
    _membersCache[patientId] = members;
    return members;
  }

  /// "@username" for [userId] on [patientId], from cache or the server.
  /// Returns null when unknown (e.g. offline or the user left).
  Future<String?> memberHandle(String patientId, String userId) async {
    var members = _membersCache[patientId];
    if (members == null) {
      try {
        members = await listMembers(patientId);
      } catch (_) {
        return null;
      }
    }
    for (final member in members) {
      if (member.userId == userId) {
        return member.username == null ? null : '@${member.username}';
      }
    }
    return null;
  }

  Future<void> grantAccess({
    required String patientId,
    required String username,
    required PatientRole role,
  }) async {
    await _remote.grantAccess(
      patientId: patientId,
      username: normalizeUsername(username),
      role: role,
    );
    _membersCache.remove(patientId);
  }

  Future<void> changeRole({
    required String patientId,
    required String userId,
    required PatientRole role,
  }) async {
    await _remote.changeRole(patientId: patientId, userId: userId, role: role);
    _membersCache.remove(patientId);
    if (userId == _currentAuthUserId()) {
      await _db.patientAccessDao.upsertMembership(
        patientId: patientId,
        role: role.wire,
        updatedAt: DateTime.now().toUtc(),
      );
      _notifier?.markChanged();
      _requestSync();
    }
  }

  /// Removes [userId]'s access. When the caller leaves, the patient's local
  /// cache is evicted immediately rather than waiting for the next sync.
  Future<void> revokeAccess({
    required String patientId,
    required String userId,
  }) async {
    await _remote.revokeAccess(patientId: patientId, userId: userId);
    _membersCache.remove(patientId);
    if (userId == _currentAuthUserId()) {
      await _db.evictPatient(patientId);
      _notifier?.markChanged();
      _requestSync();
    }
  }
}
