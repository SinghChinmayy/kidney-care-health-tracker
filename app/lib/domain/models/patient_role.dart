/// A user's role on a patient (mirrors `public.patient_access.role`).
enum PatientRole {
  owner,
  caregiver,
  viewer;

  static PatientRole? fromWire(String? value) {
    for (final role in values) {
      if (role.name == value) {
        return role;
      }
    }
    return null;
  }

  String get wire => name;

  String get label => switch (this) {
        PatientRole.owner => 'Owner',
        PatientRole.caregiver => 'Caregiver',
        PatientRole.viewer => 'Viewer',
      };

  String get description => switch (this) {
        PatientRole.owner => 'Full access and can manage who has access',
        PatientRole.caregiver => 'Can view and log vitals',
        PatientRole.viewer => 'Can view only',
      };

  /// May log/edit vitals, preferences, schedules and the profile.
  bool get canWrite => this != PatientRole.viewer;

  /// May grant, change or revoke other people's access.
  bool get canManageAccess => this == PatientRole.owner;
}

/// Thrown when a write is attempted on a patient the user can only view.
class ReadOnlyPatientException implements Exception {
  const ReadOnlyPatientException();

  @override
  String toString() => 'You have view-only access to this patient.';
}
