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
    final result = await _client.rpc<Map<String, dynamic>>(
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
    );
    return Map<String, dynamic>.from(result);
  }
}
