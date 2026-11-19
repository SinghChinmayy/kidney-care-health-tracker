import 'package:app/domain/models/patient_role.dart';

/// Someone with access to a patient (from `list_patient_members`).
class PatientMember {
  const PatientMember({
    required this.userId,
    required this.role,
    required this.isPatient,
    this.username,
    this.grantedAt,
  });

  final String userId;

  /// Null when the member hasn't picked a username yet.
  final String? username;
  final PatientRole role;

  /// True for the account the record describes (cannot be removed).
  final bool isPatient;
  final DateTime? grantedAt;

  String get handle => username == null ? 'Member' : '@$username';
}

/// Usernames: lowercase a-z, 0-9, underscore, 3-30 chars (server CHECK).
final usernamePattern = RegExp(r'^[a-z0-9_]{3,30}$');

String normalizeUsername(String input) => input.trim().toLowerCase();

String? validateUsername(String? input) {
  final value = normalizeUsername(input ?? '');
  if (value.isEmpty) {
    return 'Choose a username';
  }
  if (!usernamePattern.hasMatch(value)) {
    return '3–30 characters: letters, numbers or underscore';
  }
  return null;
}

/// User-facing failure from a sharing RPC; [message] is safe to show.
class SharingException implements Exception {
  const SharingException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
