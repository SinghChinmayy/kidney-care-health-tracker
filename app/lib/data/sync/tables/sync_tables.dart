import 'dart:developer' as developer;

import 'package:app/data/local/app_database.dart';
import 'package:app/data/sync/remote_mappers.dart';
import 'package:app/data/sync/sync_utils.dart';
import 'package:app/data/sync/syncable_table.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientsSync implements SyncableTable {
  PatientsSync({
    required AppDatabase db,
    required String? Function() currentAuthUserId,
  })  : _db = db,
        _currentAuthUserId = currentAuthUserId;

  final AppDatabase _db;
  final String? Function() _currentAuthUserId;

  @override
  String get tableKey => remoteTableName;

  @override
  String get remoteTableName => 'patients';

  @override
  Future<void> push(SupabaseClient supabase) async {
    final dirtyRows = await _db.patientsDao.getDirtyRows();
    if (dirtyRows.isEmpty) {
      return;
    }

    final payload = dirtyRows.map(patientRowToRemoteJson).toList();
    final response = await supabase
        .from(remoteTableName)
        .upsert(payload, onConflict: 'id')
        .select();

    await _applyPushResult(List<Map<String, dynamic>>.from(response));
  }

  @override
  Future<void> pull(SupabaseClient supabase) async {
    final authUserId = _currentAuthUserId();
    if (authUserId == null) {
      return;
    }

    final lastPulledAt = await _db.syncStateDao.getLastPulledAt(tableKey);
    var query = supabase.from(remoteTableName).select().eq('auth_user_id', authUserId);
    if (lastPulledAt != null) {
      query = query.gt('updated_at', remoteIsoDateTime(lastPulledAt)!);
    }

    final response = await query.order('updated_at');
    final rows = List<Map<String, dynamic>>.from(response);
    var maxUpdatedAt = lastPulledAt;

    for (final remote in rows) {
      await _applyPulledRow(remote);
      final updatedAt = parseRemoteDateTime(remote['updated_at']);
      if (maxUpdatedAt == null || updatedAt.isAfter(maxUpdatedAt)) {
        maxUpdatedAt = updatedAt;
      }
    }

    if (maxUpdatedAt != lastPulledAt) {
      await _db.syncStateDao.setLastPulledAt(tableKey, maxUpdatedAt);
    }
  }

  Future<void> _applyPushResult(List<Map<String, dynamic>> serverRows) async {
    for (final serverRow in serverRows) {
      final id = serverRow['id'] as String;
      final updatedAt = parseRemoteDateTime(serverRow['updated_at']);
      await _db.patientsDao.markSynced(id, updatedAt);
    }
  }

  Future<void> _applyPulledRow(Map<String, dynamic> remote) async {
    final remoteRow = patientRowFromRemoteJson(remote);
    final localByAuth =
        await _db.patientsDao.getRowByAuthUserId(remoteRow.authUserId);

    if (localByAuth != null && localByAuth.id != remoteRow.id) {
      await _db.reconcilePatientId(
        oldPatientId: localByAuth.id,
        newPatientId: remoteRow.id,
      );
    }

    final local = await _db.patientsDao.getRowById(remoteRow.id) ?? localByAuth;
    if (local == null) {
      await _db.patientsDao.upsertRemoteRow(remoteRow, isDirty: false);
      return;
    }

    if (shouldApplyRemoteUpdate(
      remoteUpdatedAt: remoteRow.updatedAt,
      localUpdatedAt: local.updatedAt,
    )) {
      await _db.patientsDao.upsertRemoteRow(remoteRow, isDirty: false);
    }
  }
}

class BpSync implements SyncableTable {
  BpSync({
    required AppDatabase db,
    required String? Function() currentAuthUserId,
  })  : _db = db,
        _currentAuthUserId = currentAuthUserId;

  final AppDatabase _db;
  final String? Function() _currentAuthUserId;

  @override
  String get tableKey => remoteTableName;

  @override
  String get remoteTableName => 'blood_pressure_readings';

  @override
  Future<void> push(SupabaseClient supabase) async {
    final dirtyRows = await _db.bloodPressureDao.getDirtyRows();
    if (dirtyRows.isEmpty) {
      return;
    }

    final payload = dirtyRows.map(bloodPressureRowToRemoteJson).toList();
    final response = await supabase
        .from(remoteTableName)
        .upsert(payload, onConflict: 'id')
        .select();

    for (final serverRow in List<Map<String, dynamic>>.from(response)) {
      final id = serverRow['id'] as String;
      final updatedAt = parseRemoteDateTime(serverRow['updated_at']);
      await _db.bloodPressureDao.markSynced(id, updatedAt);
    }
  }

  @override
  Future<void> pull(SupabaseClient supabase) async {
    final patientId = await _resolvePatientId();
    if (patientId == null) {
      return;
    }

    final lastPulledAt = await _db.syncStateDao.getLastPulledAt(tableKey);
    var query =
        supabase.from(remoteTableName).select().eq('patient_id', patientId);
    if (lastPulledAt != null) {
      query = query.gt('updated_at', remoteIsoDateTime(lastPulledAt)!);
    }

    final response = await query.order('updated_at');
    final rows = List<Map<String, dynamic>>.from(response);
    var maxUpdatedAt = lastPulledAt;

    for (final remote in rows) {
      await _applyPulledRow(remote);
      final updatedAt = parseRemoteDateTime(remote['updated_at']);
      if (maxUpdatedAt == null || updatedAt.isAfter(maxUpdatedAt)) {
        maxUpdatedAt = updatedAt;
      }
    }

    if (maxUpdatedAt != lastPulledAt) {
      await _db.syncStateDao.setLastPulledAt(tableKey, maxUpdatedAt);
    }
  }

  Future<void> _applyPulledRow(Map<String, dynamic> remote) async {
    final remoteRow = bloodPressureRowFromRemoteJson(remote);
    final local = await _db.bloodPressureDao.getRowById(remoteRow.id);
    if (local == null) {
      await _db.bloodPressureDao.upsertRemoteRow(remoteRow, isDirty: false);
      return;
    }

    if (shouldApplyRemoteUpdate(
      remoteUpdatedAt: remoteRow.updatedAt,
      localUpdatedAt: local.updatedAt,
    )) {
      await _db.bloodPressureDao.upsertRemoteRow(remoteRow, isDirty: false);
    }
  }

  Future<String?> _resolvePatientId() async {
    final authUserId = _currentAuthUserId();
    if (authUserId == null) {
      return null;
    }
    return _db.patientIdForAuthUser(authUserId);
  }
}

class GlucoseSync implements SyncableTable {
  GlucoseSync({
    required AppDatabase db,
    required String? Function() currentAuthUserId,
  })  : _db = db,
        _currentAuthUserId = currentAuthUserId;

  final AppDatabase _db;
  final String? Function() _currentAuthUserId;

  @override
  String get tableKey => remoteTableName;

  @override
  String get remoteTableName => 'blood_glucose_readings';

  @override
  Future<void> push(SupabaseClient supabase) async {
    final dirtyRows = await _db.bloodGlucoseDao.getDirtyRows();
    if (dirtyRows.isEmpty) {
      return;
    }

    final payload = dirtyRows.map(bloodGlucoseRowToRemoteJson).toList();
    final response = await supabase
        .from(remoteTableName)
        .upsert(payload, onConflict: 'id')
        .select();

    for (final serverRow in List<Map<String, dynamic>>.from(response)) {
      final id = serverRow['id'] as String;
      final updatedAt = parseRemoteDateTime(serverRow['updated_at']);
      await _db.bloodGlucoseDao.markSynced(id, updatedAt);
    }
  }

  @override
  Future<void> pull(SupabaseClient supabase) async {
    final patientId = await _resolvePatientId();
    if (patientId == null) {
      return;
    }

    final lastPulledAt = await _db.syncStateDao.getLastPulledAt(tableKey);
    var query =
        supabase.from(remoteTableName).select().eq('patient_id', patientId);
    if (lastPulledAt != null) {
      query = query.gt('updated_at', remoteIsoDateTime(lastPulledAt)!);
    }

    final response = await query.order('updated_at');
    final rows = List<Map<String, dynamic>>.from(response);
    var maxUpdatedAt = lastPulledAt;

    for (final remote in rows) {
      await _applyPulledRow(remote);
      final updatedAt = parseRemoteDateTime(remote['updated_at']);
      if (maxUpdatedAt == null || updatedAt.isAfter(maxUpdatedAt)) {
        maxUpdatedAt = updatedAt;
      }
    }

    if (maxUpdatedAt != lastPulledAt) {
      await _db.syncStateDao.setLastPulledAt(tableKey, maxUpdatedAt);
    }
  }

  Future<void> _applyPulledRow(Map<String, dynamic> remote) async {
    final remoteRow = bloodGlucoseRowFromRemoteJson(remote);
    final local = await _db.bloodGlucoseDao.getRowById(remoteRow.id);
    if (local == null) {
      await _db.bloodGlucoseDao.upsertRemoteRow(remoteRow, isDirty: false);
      return;
    }

    if (shouldApplyRemoteUpdate(
      remoteUpdatedAt: remoteRow.updatedAt,
      localUpdatedAt: local.updatedAt,
    )) {
      await _db.bloodGlucoseDao.upsertRemoteRow(remoteRow, isDirty: false);
    }
  }

  Future<String?> _resolvePatientId() async {
    final authUserId = _currentAuthUserId();
    if (authUserId == null) {
      return null;
    }
    return _db.patientIdForAuthUser(authUserId);
  }
}

class WeightSync implements SyncableTable {
  WeightSync({
    required AppDatabase db,
    required String? Function() currentAuthUserId,
  })  : _db = db,
        _currentAuthUserId = currentAuthUserId;

  final AppDatabase _db;
  final String? Function() _currentAuthUserId;

  @override
  String get tableKey => remoteTableName;

  @override
  String get remoteTableName => 'weight_readings';

  @override
  Future<void> push(SupabaseClient supabase) async {
    final dirtyRows = await _db.weightDao.getDirtyRows();
    if (dirtyRows.isEmpty) {
      return;
    }

    final payload = dirtyRows.map(weightRowToRemoteJson).toList();
    final response = await supabase
        .from(remoteTableName)
        .upsert(payload, onConflict: 'id')
        .select();

    for (final serverRow in List<Map<String, dynamic>>.from(response)) {
      final id = serverRow['id'] as String;
      final updatedAt = parseRemoteDateTime(serverRow['updated_at']);
      await _db.weightDao.markSynced(id, updatedAt);
    }
  }

  @override
  Future<void> pull(SupabaseClient supabase) async {
    final patientId = await _resolvePatientId();
    if (patientId == null) {
      return;
    }

    final lastPulledAt = await _db.syncStateDao.getLastPulledAt(tableKey);
    var query =
        supabase.from(remoteTableName).select().eq('patient_id', patientId);
    if (lastPulledAt != null) {
      query = query.gt('updated_at', remoteIsoDateTime(lastPulledAt)!);
    }

    final response = await query.order('updated_at');
    final rows = List<Map<String, dynamic>>.from(response);
    var maxUpdatedAt = lastPulledAt;

    for (final remote in rows) {
      await _applyPulledRow(remote);
      final updatedAt = parseRemoteDateTime(remote['updated_at']);
      if (maxUpdatedAt == null || updatedAt.isAfter(maxUpdatedAt)) {
        maxUpdatedAt = updatedAt;
      }
    }

    if (maxUpdatedAt != lastPulledAt) {
      await _db.syncStateDao.setLastPulledAt(tableKey, maxUpdatedAt);
    }
  }

  Future<void> _applyPulledRow(Map<String, dynamic> remote) async {
    final remoteRow = weightRowFromRemoteJson(remote);
    final local = await _db.weightDao.getRowById(remoteRow.id);
    if (local == null) {
      await _db.weightDao.upsertRemoteRow(remoteRow, isDirty: false);
      return;
    }

    if (shouldApplyRemoteUpdate(
      remoteUpdatedAt: remoteRow.updatedAt,
      localUpdatedAt: local.updatedAt,
    )) {
      await _db.weightDao.upsertRemoteRow(remoteRow, isDirty: false);
    }
  }

  Future<String?> _resolvePatientId() async {
    final authUserId = _currentAuthUserId();
    if (authUserId == null) {
      return null;
    }
    return _db.patientIdForAuthUser(authUserId);
  }
}

class PatientPreferencesSync implements SyncableTable {
  PatientPreferencesSync({
    required AppDatabase db,
    required String? Function() currentAuthUserId,
  })  : _db = db,
        _currentAuthUserId = currentAuthUserId;

  final AppDatabase _db;
  final String? Function() _currentAuthUserId;

  @override
  String get tableKey => remoteTableName;

  @override
  String get remoteTableName => 'patient_preferences';

  @override
  Future<void> push(SupabaseClient supabase) async {
    final dirtyRows = await _db.patientPreferencesDao.getDirtyRows();
    if (dirtyRows.isEmpty) {
      return;
    }

    for (final row in dirtyRows) {
      // Remap to remote bootstrap id when local seed used a different UUID.
      final existing = await supabase
          .from(remoteTableName)
          .select('id')
          .eq('patient_id', row.patientId)
          .maybeSingle();
      final remoteId = existing?['id'] as String?;
      var local = row;
      if (remoteId != null && remoteId != row.id) {
        await _db.patientPreferencesDao.rebindId(
          oldId: row.id,
          newId: remoteId,
        );
        local = (await _db.patientPreferencesDao.getRowById(remoteId))!;
      }

      final response = await supabase
          .from(remoteTableName)
          .upsert(
            patientPreferencesRowToRemoteJson(local),
            onConflict: 'id',
          )
          .select();

      for (final serverRow in List<Map<String, dynamic>>.from(response)) {
        final id = serverRow['id'] as String;
        final updatedAt = parseRemoteDateTime(serverRow['updated_at']);
        await _db.patientPreferencesDao.markSynced(id, updatedAt);
      }
    }
  }

  @override
  Future<void> pull(SupabaseClient supabase) async {
    final patientId = await _resolvePatientId();
    if (patientId == null) {
      return;
    }

    final lastPulledAt = await _db.syncStateDao.getLastPulledAt(tableKey);
    var query =
        supabase.from(remoteTableName).select().eq('patient_id', patientId);
    if (lastPulledAt != null) {
      query = query.gt('updated_at', remoteIsoDateTime(lastPulledAt)!);
    }

    final response = await query.order('updated_at');
    final rows = List<Map<String, dynamic>>.from(response);
    var maxUpdatedAt = lastPulledAt;

    for (final remote in rows) {
      await _applyPulledRow(remote);
      final updatedAt = parseRemoteDateTime(remote['updated_at']);
      if (maxUpdatedAt == null || updatedAt.isAfter(maxUpdatedAt)) {
        maxUpdatedAt = updatedAt;
      }
    }

    if (maxUpdatedAt != lastPulledAt) {
      await _db.syncStateDao.setLastPulledAt(tableKey, maxUpdatedAt);
    }
  }

  Future<void> _applyPulledRow(Map<String, dynamic> remote) async {
    final remoteRow = patientPreferencesRowFromRemoteJson(remote);
    final localByPatient =
        await _db.patientPreferencesDao.getRowByPatientId(remoteRow.patientId);

    if (localByPatient != null && localByPatient.id != remoteRow.id) {
      if (localByPatient.isDirty &&
          !shouldApplyRemoteUpdate(
            remoteUpdatedAt: remoteRow.updatedAt,
            localUpdatedAt: localByPatient.updatedAt,
          )) {
        await _db.patientPreferencesDao.rebindId(
          oldId: localByPatient.id,
          newId: remoteRow.id,
        );
        return;
      }
      await _db.patientPreferencesDao.deleteById(localByPatient.id);
      await _db.patientPreferencesDao.upsertRemoteRow(
        remoteRow,
        isDirty: false,
      );
      return;
    }

    final local = localByPatient ??
        await _db.patientPreferencesDao.getRowById(remoteRow.id);
    if (local == null) {
      await _db.patientPreferencesDao.upsertRemoteRow(
        remoteRow,
        isDirty: false,
      );
      return;
    }

    if (shouldApplyRemoteUpdate(
      remoteUpdatedAt: remoteRow.updatedAt,
      localUpdatedAt: local.updatedAt,
    )) {
      await _db.patientPreferencesDao.upsertRemoteRow(
        remoteRow,
        isDirty: false,
      );
    }
  }

  Future<String?> _resolvePatientId() async {
    final authUserId = _currentAuthUserId();
    if (authUserId == null) {
      return null;
    }
    return _db.patientIdForAuthUser(authUserId);
  }
}

class FluidIntakeSync implements SyncableTable {
  FluidIntakeSync({
    required AppDatabase db,
    required String? Function() currentAuthUserId,
  })  : _db = db,
        _currentAuthUserId = currentAuthUserId;

  final AppDatabase _db;
  final String? Function() _currentAuthUserId;

  @override
  String get tableKey => remoteTableName;

  @override
  String get remoteTableName => 'fluid_intake_logs';

  @override
  Future<void> push(SupabaseClient supabase) async {
    final dirtyRows = await _db.fluidIntakeDao.getDirtyRows();
    if (dirtyRows.isEmpty) {
      return;
    }

    final payload = dirtyRows.map(fluidIntakeRowToRemoteJson).toList();
    final response = await supabase
        .from(remoteTableName)
        .upsert(payload, onConflict: 'id')
        .select();

    for (final serverRow in List<Map<String, dynamic>>.from(response)) {
      final id = serverRow['id'] as String;
      final updatedAt = parseRemoteDateTime(serverRow['updated_at']);
      await _db.fluidIntakeDao.markSynced(id, updatedAt);
    }
  }

  @override
  Future<void> pull(SupabaseClient supabase) async {
    final patientId = await _resolvePatientId();
    if (patientId == null) {
      return;
    }

    final lastPulledAt = await _db.syncStateDao.getLastPulledAt(tableKey);
    var query =
        supabase.from(remoteTableName).select().eq('patient_id', patientId);
    if (lastPulledAt != null) {
      query = query.gt('updated_at', remoteIsoDateTime(lastPulledAt)!);
    }

    final response = await query.order('updated_at');
    final rows = List<Map<String, dynamic>>.from(response);
    var maxUpdatedAt = lastPulledAt;

    for (final remote in rows) {
      await _applyPulledRow(remote);
      final updatedAt = parseRemoteDateTime(remote['updated_at']);
      if (maxUpdatedAt == null || updatedAt.isAfter(maxUpdatedAt)) {
        maxUpdatedAt = updatedAt;
      }
    }

    if (maxUpdatedAt != lastPulledAt) {
      await _db.syncStateDao.setLastPulledAt(tableKey, maxUpdatedAt);
    }
  }

  Future<void> _applyPulledRow(Map<String, dynamic> remote) async {
    final remoteRow = fluidIntakeRowFromRemoteJson(remote);
    final local = await _db.fluidIntakeDao.getRowById(remoteRow.id);
    if (local == null) {
      await _db.fluidIntakeDao.upsertRemoteRow(remoteRow, isDirty: false);
      return;
    }

    if (shouldApplyRemoteUpdate(
      remoteUpdatedAt: remoteRow.updatedAt,
      localUpdatedAt: local.updatedAt,
    )) {
      await _db.fluidIntakeDao.upsertRemoteRow(remoteRow, isDirty: false);
    }
  }

  Future<String?> _resolvePatientId() async {
    final authUserId = _currentAuthUserId();
    if (authUserId == null) {
      return null;
    }
    return _db.patientIdForAuthUser(authUserId);
  }
}

void logSyncError(String tableKey, Object error, StackTrace stackTrace) {
  developer.log(
    'Sync failed for $tableKey',
    error: error,
    stackTrace: stackTrace,
    name: 'SyncEngine',
  );
}
