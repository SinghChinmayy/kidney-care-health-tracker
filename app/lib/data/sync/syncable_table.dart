import 'package:supabase_flutter/supabase_flutter.dart';

/// Registry entry for one synced table (see planning/sync/v0/stage-1.md §5.1).
abstract class SyncableTable {
  /// Key stored in local [SyncState.tableKey] (matches remote table name).
  String get tableKey;

  /// Postgres table name used in Supabase queries.
  String get remoteTableName;

  Future<void> push(SupabaseClient supabase);

  Future<void> pull(SupabaseClient supabase);
}
