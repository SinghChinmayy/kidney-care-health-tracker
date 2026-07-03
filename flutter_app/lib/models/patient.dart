/// Mirrors the `public.patients` row shape (see
/// `planning/db/v0/stage-1.2.dbml`). Kept intentionally close to the raw
/// column set so mapping to/from Supabase JSON stays a straight line —
/// this will also be the shape the local drift table mirrors 1:1 once the
/// offline sync engine is built (see `planning/sync/v0/stage-1.md`).
class Patient {
  const Patient({
    required this.id,
    required this.authUserId,
    this.fullName,
    this.dateOfBirth,
    this.sex,
    this.ckdStage,
    this.dialysisType,
    this.heightCm,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      authUserId: json['auth_user_id'] as String,
      fullName: json['full_name'] as String?,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      sex: json['sex'] as String?,
      ckdStage: json['ckd_stage'] as String?,
      dialysisType: json['dialysis_type'] as String?,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String authUserId;
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? sex;
  final String? ckdStage;
  final String? dialysisType;
  final double? heightCm;

  /// Per the signup bootstrap trigger, a bare row is created with
  /// `full_name = NULL` before onboarding — treat that as the single
  /// "profile incomplete" signal for now (see sync plan §12.1 / open Q6).
  bool get isProfileComplete => fullName != null && fullName!.trim().isNotEmpty;
}
