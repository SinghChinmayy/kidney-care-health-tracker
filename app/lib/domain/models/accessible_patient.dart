import 'package:app/domain/models/patient.dart';
import 'package:app/domain/models/patient_role.dart';

/// A patient the signed-in user can access, with their role.
class AccessiblePatient {
  const AccessiblePatient({
    required this.patient,
    required this.role,
    required this.isSelf,
  });

  final Patient patient;
  final PatientRole role;

  /// True for the signed-in user's own record (patients.auth_user_id).
  final bool isSelf;

  String get displayName {
    final name = patient.displayName;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return isSelf ? 'You' : 'Unnamed patient';
  }
}
