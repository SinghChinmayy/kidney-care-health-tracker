import 'package:app/data/local/app_database.dart';
import 'package:app/data/sync/sync_utils.dart';
import 'package:app/data/sync/syncable_table.dart';
import 'package:app/domain/models/patient_role.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccessRefreshResult {
  const AccessRefreshResult({required this.scope, required this.changed});

  final SyncScope scope;

  /// True when patients were added, removed, or changed role locally.
  final bool changed;
}

/// Reconciles the local membership cache with the server's
/// `patient_access` rows for the signed-in user, before tables sync.
///
/// - Revoked patient: every cached row is evicted.
/// - New grant: per-patient cursors are cleared so the next pull is full,
///   regardless of how far other patients' cursors have advanced.
/// - Read-only (viewer) patient with unpushed local edits: those edits can
///   never be accepted, so the patient's cache is discarded and re-pulled.
class PatientAccessSync {
  PatientAccessSync({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  static const remoteTableName = 'patient_access';

  Future<AccessRefreshResult> refresh(
    SupabaseClient supabase,
    String authUserId,
  ) async {
    final response = await supabase
        .from(remoteTableName)
        .select('patient_id, role, updated_at')
        .eq('user_id', authUserId);
    final remote = <String, ({PatientRole role, DateTime updatedAt})>{};
    for (final row in List<Map<String, dynamic>>.from(response)) {
      final role = PatientRole.fromWire(row['role'] as String?);
      if (role == null) {
        continue;
      }
      remote[row['patient_id'] as String] = (
        role: role,
        updatedAt: parseRemoteDateTime(row['updated_at']),
      );
    }

    final local = {
      for (final m in await _db.patientAccessDao.getMemberships())
        m.patientId: m,
    };
    var changed = false;

    for (final patientId in local.keys) {
      if (!remote.containsKey(patientId)) {
        await _db.evictPatient(patientId);
        changed = true;
      }
    }

    for (final entry in remote.entries) {
      final patientId = entry.key;
      final previous = local[patientId];
      if (previous == null) {
        await _clearCursors(patientId);
        changed = true;
      } else if (previous.role != entry.value.role.wire) {
        changed = true;
      }

      if (!entry.value.role.canWrite &&
          await _db.hasDirtyRowsForPatient(patientId)) {
        await _db.evictPatient(patientId, keepMembership: true);
        changed = true;
      }

      await _db.patientAccessDao.upsertMembership(
        patientId: patientId,
        role: entry.value.role.wire,
        updatedAt: entry.value.updatedAt,
      );
    }

    return AccessRefreshResult(
      scope: _scopeFrom(
        authUserId,
        {for (final e in remote.entries) e.key: e.value.role},
      ),
      changed: changed,
    );
  }

  /// Scope from the local cache, used when the server cannot be reached.
  Future<SyncScope> localScope(String authUserId) async {
    final roles = <String, PatientRole>{};
    for (final m in await _db.patientAccessDao.getMemberships()) {
      final role = PatientRole.fromWire(m.role);
      if (role != null) {
        roles[m.patientId] = role;
      }
    }
    // Before the first access refresh the self patient is the only one.
    final selfId = await _db.patientIdForAuthUser(authUserId);
    if (selfId != null) {
      roles.putIfAbsent(selfId, () => PatientRole.owner);
    }
    return _scopeFrom(authUserId, roles);
  }

  SyncScope _scopeFrom(String authUserId, Map<String, PatientRole> roles) {
    return SyncScope(
      authUserId: authUserId,
      patientIds: roles.keys.toList(),
      writablePatientIds: {
        for (final e in roles.entries)
          if (e.value.canWrite) e.key,
      },
    );
  }

  Future<void> _clearCursors(String patientId) {
    return (_db.delete(_db.syncState)
          ..where((t) => t.tableKey.like('%:$patientId')))
        .go();
  }
}
