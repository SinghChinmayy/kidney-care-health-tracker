import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient.dart';

/// Reads/writes the signed-in user's `patients` row.
///
/// The row itself is guaranteed to already exist by the time this is
/// called — a Postgres trigger creates a bare row (`full_name = NULL`) the
/// moment the `auth.users` record is inserted at signup (see
/// `planning/sync/v0/stage-1.md` §7.2). This repository never inserts a
/// `patients` row itself, only reads/updates the one the trigger created.
///
/// This is a direct-to-Supabase implementation for now. Once the local
/// drift store + sync engine are built, this will be replaced by reads
/// against the local table with the sync engine keeping it up to date.
class PatientRepository {
  PatientRepository(this._client);

  final SupabaseClient _client;

  Future<Patient> fetchCurrentPatient() async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) {
      throw StateError('No signed-in user; cannot fetch patient profile.');
    }
    final row = await _client
        .from('patients')
        .select()
        .eq('auth_user_id', authUserId)
        .single();
    return Patient.fromJson(row);
  }

  Future<Patient> updateProfile({
    required String fullName,
    DateTime? dateOfBirth,
    String? sex,
    String? ckdStage,
    String? dialysisType,
    double? heightCm,
  }) async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) {
      throw StateError('No signed-in user; cannot update patient profile.');
    }
    final row = await _client
        .from('patients')
        .update({
          'full_name': fullName,
          'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
          'sex': sex,
          'ckd_stage': ckdStage,
          'dialysis_type': dialysisType,
          'height_cm': heightCm,
        })
        .eq('auth_user_id', authUserId)
        .select()
        .single();
    return Patient.fromJson(row);
  }
}
