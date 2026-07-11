class Patient {
  const Patient({
    required this.id,
    required this.authUserId,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.sex,
    this.ckdStage,
    this.dialysisType = 'none',
    this.dialysisDaysOfWeek,
    this.heightCm,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String authUserId;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? sex;
  final String? ckdStage;
  final String dialysisType;

  /// ISO weekdays 1=Mon … 7=Sun. null = unset; empty = no days.
  final List<int>? dialysisDaysOfWeek;
  final double? heightCm;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isProfileComplete =>
      firstName != null &&
      firstName!.isNotEmpty &&
      lastName != null &&
      lastName!.isNotEmpty;

  String? get displayName {
    if (firstName == null && lastName == null) return null;
    return [firstName, lastName].whereType<String>().join(' ').trim();
  }
}
