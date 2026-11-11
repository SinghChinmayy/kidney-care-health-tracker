import 'package:app/domain/models/patient_member.dart';
import 'package:app/domain/models/patient_role.dart';
import 'package:app/data/sync/sync_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-side patient/access operations. These are SECURITY DEFINER RPCs
/// (planning/db/v0/s2/s2.3–s2.4); they need a network connection and are
/// never queued offline.
abstract interface class PatientAccessRemote {
  /// Calls `public.create_patient`; returns the created `patients` row.
  Future<Map<String, dynamic>> createPatient({
    required String id,
    required String firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? sex,
    String? bloodGroup,
  });

  Future<String?> getMyUsername(String userId);

  /// Upserts the caller's `profiles` row.
  Future<void> setMyUsername(String userId, String username);

  Future<List<PatientMember>> listMembers(String patientId);

  Future<void> grantAccess({
    required String patientId,
    required String username,
    required PatientRole role,
  });

  Future<void> changeRole({
    required String patientId,
    required String userId,
    required PatientRole role,
  });

  Future<void> revokeAccess({
    required String patientId,
    required String userId,
  });
}

class SupabasePatientAccessRemote implements PatientAccessRemote {
  SupabasePatientAccessRemote({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> createPatient({
    required String id,
    required String firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? sex,
    String? bloodGroup,
  }) async {
    final result = await _guard(
      () => _client.rpc<Map<String, dynamic>>(
        'create_patient',
        params: {
          'p_id': id,
          'p_first_name': firstName,
          'p_last_name': lastName,
          'p_date_of_birth': dateOfBirth == null
              ? null
              : '${dateOfBirth.year.toString().padLeft(4, '0')}-'
                  '${dateOfBirth.month.toString().padLeft(2, '0')}-'
                  '${dateOfBirth.day.toString().padLeft(2, '0')}',
          'p_sex': sex,
          'p_blood_group': bloodGroup,
        },
      ),
    );
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<String?> getMyUsername(String userId) async {
    final row = await _guard(
      () => _client
          .from('profiles')
          .select('username')
          .eq('user_id', userId)
          .maybeSingle(),
    );
    return row?['username'] as String?;
  }

  @override
  Future<void> setMyUsername(String userId, String username) {
    return _guard(
      () => _client.from('profiles').upsert(
        {'user_id': userId, 'username': normalizeUsername(username)},
        onConflict: 'user_id',
      ),
    );
  }

  @override
  Future<List<PatientMember>> listMembers(String patientId) async {
    final rows = await _guard(
      () => _client.rpc<List<dynamic>>(
        'list_patient_members',
        params: {'p_patient_id': patientId},
      ),
    );
    return [
      for (final raw in rows)
        if (raw is Map<String, dynamic>)
          if (PatientRole.fromWire(raw['role'] as String?) case final role?)
            PatientMember(
              userId: raw['user_id'] as String,
              username: raw['username'] as String?,
              role: role,
              isPatient: raw['is_patient'] as bool? ?? false,
              grantedAt: parseRemoteDateTimeOrNull(raw['granted_at']),
            ),
    ];
  }

  @override
  Future<void> grantAccess({
    required String patientId,
    required String username,
    required PatientRole role,
  }) {
    return _guard(
      () => _client.rpc<void>(
        'grant_patient_access',
        params: {
          'p_patient_id': patientId,
          'p_username': normalizeUsername(username),
          'p_role': role.wire,
        },
      ),
    );
  }

  @override
  Future<void> changeRole({
    required String patientId,
    required String userId,
    required PatientRole role,
  }) {
    return _guard(
      () => _client.rpc<void>(
        'change_patient_access_role',
        params: {
          'p_patient_id': patientId,
          'p_user_id': userId,
          'p_role': role.wire,
        },
      ),
    );
  }

  @override
  Future<void> revokeAccess({
    required String patientId,
    required String userId,
  }) {
    return _guard(
      () => _client.rpc<void>(
        'revoke_patient_access',
        params: {'p_patient_id': patientId, 'p_user_id': userId},
      ),
    );
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (error) {
      throw sharingExceptionFrom(error);
    }
  }
}

/// Maps RPC error messages / Postgres codes to user-facing text.
SharingException sharingExceptionFrom(PostgrestException error) {
  final key = error.message.trim();
  final message = switch (key) {
    'user_not_found' => 'No one has that username.',
    'already_has_access' => 'That person already has access.',
    'last_owner' => 'A patient must always have at least one owner.',
    'cannot_remove_patient_self' =>
      "The patient's own account can't be removed.",
    'cannot_change_patient_self' =>
      "Only the patient can change their own role.",
    'not_authorized' => "You don't have permission to do that.",
    'access_not_found' => 'That person no longer has access.',
    'invalid_role' => 'Unknown role.',
    'first_name_required' => 'First name is required.',
    _ => switch (error.code) {
        // profiles_username_key unique violation
        '23505' => 'That username is taken.',
        '23514' => 'That username is not allowed.',
        _ => 'Something went wrong. Check your connection and try again.',
      },
  };
  return SharingException(message, code: key);
}
