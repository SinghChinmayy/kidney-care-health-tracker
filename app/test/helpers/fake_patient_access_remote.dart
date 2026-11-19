import 'package:app/data/services/patient_access_remote.dart';
import 'package:app/domain/models/patient_member.dart';
import 'package:app/domain/models/patient_role.dart';

/// In-memory sharing backend mirroring the server rules that matter to
/// the client (owner-only management, last owner, unknown usernames).
class FakePatientAccessRemote implements PatientAccessRemote {
  FakePatientAccessRemote({required this.me});

  final String me;
  final Map<String, String> usernames = {}; // userId -> username
  final Map<String, List<PatientMember>> members = {}; // patientId -> list
  final List<String> calls = [];

  PatientRole? _roleOf(String patientId, String userId) {
    for (final m in members[patientId] ?? const <PatientMember>[]) {
      if (m.userId == userId) {
        return m.role;
      }
    }
    return null;
  }

  void addMember(
    String patientId,
    String userId,
    PatientRole role, {
    bool isPatient = false,
  }) {
    members.putIfAbsent(patientId, () => []).add(
          PatientMember(
            userId: userId,
            username: usernames[userId],
            role: role,
            isPatient: isPatient,
          ),
        );
  }

  @override
  Future<Map<String, dynamic>> createPatient({
    required String id,
    required String firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? sex,
    String? bloodGroup,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String?> getMyUsername(String userId) async => usernames[userId];

  @override
  Future<void> setMyUsername(String userId, String username) async {
    calls.add('setUsername:$username');
    if (usernames.entries.any((e) => e.value == username && e.key != userId)) {
      throw const SharingException('That username is taken.');
    }
    usernames[userId] = username;
  }

  @override
  Future<List<PatientMember>> listMembers(String patientId) async {
    calls.add('list:$patientId');
    if (_roleOf(patientId, me) == null) {
      throw const SharingException("You don't have permission to do that.");
    }
    return List.of(members[patientId] ?? const []);
  }

  @override
  Future<void> grantAccess({
    required String patientId,
    required String username,
    required PatientRole role,
  }) async {
    calls.add('grant:$patientId:$username:${role.wire}');
    if (_roleOf(patientId, me) != PatientRole.owner) {
      throw const SharingException("You don't have permission to do that.");
    }
    final entry = usernames.entries.where((e) => e.value == username);
    if (entry.isEmpty) {
      throw const SharingException('No one has that username.');
    }
    addMember(patientId, entry.first.key, role);
  }

  @override
  Future<void> changeRole({
    required String patientId,
    required String userId,
    required PatientRole role,
  }) async {
    calls.add('change:$patientId:$userId:${role.wire}');
    final list = members[patientId]!;
    final i = list.indexWhere((m) => m.userId == userId);
    list[i] = PatientMember(
      userId: userId,
      username: list[i].username,
      role: role,
      isPatient: list[i].isPatient,
    );
  }

  @override
  Future<void> revokeAccess({
    required String patientId,
    required String userId,
  }) async {
    calls.add('revoke:$patientId:$userId');
    final list = members[patientId]!;
    final owners = list.where((m) => m.role == PatientRole.owner).length;
    if (_roleOf(patientId, userId) == PatientRole.owner && owners <= 1) {
      throw const SharingException(
        'A patient must always have at least one owner.',
      );
    }
    list.removeWhere((m) => m.userId == userId);
  }
}
