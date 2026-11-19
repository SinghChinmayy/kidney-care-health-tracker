import 'package:supabase_flutter/supabase_flutter.dart';

/// Which patients a sync run covers, resolved from the signed-in user's
/// `patient_access` rows at the start of the run.
class SyncScope {
  const SyncScope({
    required this.authUserId,
    required this.patientIds,
    required this.writablePatientIds,
  });

  static const empty = SyncScope(
    authUserId: null,
    patientIds: [],
    writablePatientIds: {},
  );

  final String? authUserId;

  /// Every patient the user can read (pulls run once per patient).
  final List<String> patientIds;

  /// Patients the user may write (caregiver+). Dirty rows for other
  /// patients are never pushed.
  final Set<String> writablePatientIds;

  bool canWrite(String patientId) => writablePatientIds.contains(patientId);
}

/// Registry entry for one synced table (see planning/sync/v0/stage-1.md §5.1).
abstract class SyncableTable {
  /// Prefix for local [SyncState.tableKey] cursors (matches remote table
  /// name). Cursors are stored per patient as `'$tableKey:$patientId'`.
  String get tableKey;

  /// Postgres table name used in Supabase queries.
  String get remoteTableName;

  Future<void> push(SupabaseClient supabase, SyncScope scope);

  Future<void> pull(SupabaseClient supabase, SyncScope scope);
}

String patientCursorKey(String tableKey, String patientId) =>
    '$tableKey:$patientId';
