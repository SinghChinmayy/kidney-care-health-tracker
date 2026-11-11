import 'dart:developer' as developer;

import 'package:app/data/local/app_database.dart';
import 'package:app/data/sync/remote_mappers.dart';
import 'package:app/data/sync/sync_utils.dart';
import 'package:app/data/sync/syncable_table.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Incremental pull of one patient's rows from [remoteTableName], filtered
/// by [filterColumn] = patientId and the per-patient cursor. A patient with
/// no cursor (new grant, or cursors reset) gets a full pull.
Future<void> pullForPatient({
  required AppDatabase db,
  required SupabaseClient supabase,
  required String tableKey,
  required String remoteTableName,
  required String patientId,
  required Future<void> Function(Map<String, dynamic> remote) apply,
  String filterColumn = 'patient_id',
}) async {
  final cursorKey = patientCursorKey(tableKey, patientId);
  final lastPulledAt = await db.syncStateDao.getLastPulledAt(cursorKey);
  var query =
      supabase.from(remoteTableName).select().eq(filterColumn, patientId);
  if (lastPulledAt != null) {
    query = query.gt('updated_at', remoteIsoDateTime(lastPulledAt)!);
  }

  final response = await query.order('updated_at');
  final rows = List<Map<String, dynamic>>.from(response);
  var maxUpdatedAt = lastPulledAt;

  for (final remote in rows) {
    await apply(remote);
    final updatedAt = parseRemoteDateTime(remote['updated_at']);
    if (maxUpdatedAt == null || updatedAt.isAfter(maxUpdatedAt)) {
      maxUpdatedAt = updatedAt;
    }
  }

  if (maxUpdatedAt != lastPulledAt) {
    await db.syncStateDao.setLastPulledAt(cursorKey, maxUpdatedAt);
  }
}

class PatientsSync implements SyncableTable {
  PatientsSync({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  @override
  String get tableKey => remoteTableName;

  @override
  String get remoteTableName => 'patients';

  /// Patients are created server-side only (signup trigger or the
  /// create_patient RPC), so a push is always an UPDATE of an existing row.
  @override
  Future<void> push(SupabaseClient supabase, SyncScope scope) async {
    final dirtyRows = await _db.patientsDao.getDirtyRows();
    for (final row in dirtyRows) {
      if (!scope.canWrite(row.id)) {
        continue;
      }
      final payload = patientRowToRemoteJson(row)..remove('id');
      final response = await supabase
          .from(remoteTableName)
          .update(payload)
          .eq('id', row.id)
          .select();
      final serverRows = List<Map<String, dynamic>>.from(response);
      if (serverRows.isEmpty) {
        throw StateError('Patient ${row.id} update was not applied.');
      }
      for (final serverRow in serverRows) {
        await _db.patientsDao.markSynced(
          serverRow['id'] as String,
          parseRemoteDateTime(serverRow['updated_at']),
        );
      }
    }
  }

  @override
  Future<void> pull(SupabaseClient supabase, SyncScope scope) async {
    for (final patientId in scope.patientIds) {
      await pullForPatient(
        db: _db,
        supabase: supabase,
        tableKey: tableKey,
        remoteTableName: remoteTableName,
        patientId: patientId,
        filterColumn: 'id',
        apply: _applyPulledRow,
      );
    }
  }

  Future<void> _applyPulledRow(Map<String, dynamic> remote) async {
    final remoteRow = patientRowFromRemoteJson(remote);
    final authUserId = remoteRow.authUserId;
    final localByAuth = authUserId == null
        ? null
        : await _db.patientsDao.getRowByAuthUserId(authUserId);

    if (localByAuth != null && localByAuth.id != remoteRow.id) {
      await _db.reconcilePatientId(
        oldPatientId: localByAuth.id,
        newPatientId: remoteRow.id,
      );
    }

    final local = await _db.patientsDao.getRowById(remoteRow.id) ?? localByAuth;
    if (local == null ||
        shouldApplyRemoteUpdate(
          remoteUpdatedAt: remoteRow.updatedAt,
          localUpdatedAt: local.updatedAt,
        )) {
      await _db.patientsDao.upsertRemoteRow(remoteRow, isDirty: false);
    }
  }
}

/// Shared push/pull for append-style log tables keyed by `patient_id`
/// (BP, glucose, weight, fluid): batch upsert of dirty rows, LWW pull.
class PatientLogTableSync<R> implements SyncableTable {
  PatientLogTableSync({
    required AppDatabase db,
    required this.remoteTableName,
    required this.getDirtyRows,
    required this.patientIdOf,
    required this.toRemoteJson,
    required this.fromRemoteJson,
    required this.idOf,
    required this.updatedAtOf,
    required this.getRowById,
    required this.upsertRemoteRow,
    required this.markSynced,
  }) : _db = db;

  final AppDatabase _db;
  final Future<List<R>> Function() getDirtyRows;
  final String Function(R row) patientIdOf;
  final Map<String, dynamic> Function(R row) toRemoteJson;
  final R Function(Map<String, dynamic> json) fromRemoteJson;
  final String Function(R row) idOf;
  final DateTime Function(R row) updatedAtOf;
  final Future<R?> Function(String id) getRowById;
  final Future<void> Function(R row) upsertRemoteRow;
  final Future<void> Function(String id, DateTime updatedAt) markSynced;

  @override
  final String remoteTableName;

  @override
  String get tableKey => remoteTableName;

  @override
  Future<void> push(SupabaseClient supabase, SyncScope scope) async {
    final dirtyRows = (await getDirtyRows())
        .where((row) => scope.canWrite(patientIdOf(row)))
        .toList();
    if (dirtyRows.isEmpty) {
      return;
    }

    final payload = dirtyRows.map(toRemoteJson).toList();
    final response = await supabase
        .from(remoteTableName)
        .upsert(payload, onConflict: 'id')
        .select();

    for (final serverRow in List<Map<String, dynamic>>.from(response)) {
      await markSynced(
        serverRow['id'] as String,
        parseRemoteDateTime(serverRow['updated_at']),
      );
    }
  }

  @override
  Future<void> pull(SupabaseClient supabase, SyncScope scope) async {
    for (final patientId in scope.patientIds) {
      await pullForPatient(
        db: _db,
        supabase: supabase,
        tableKey: tableKey,
        remoteTableName: remoteTableName,
        patientId: patientId,
        apply: _applyPulledRow,
      );
    }
  }

  Future<void> _applyPulledRow(Map<String, dynamic> remote) async {
    final remoteRow = fromRemoteJson(remote);
    final local = await getRowById(idOf(remoteRow));
    if (local == null ||
        shouldApplyRemoteUpdate(
          remoteUpdatedAt: updatedAtOf(remoteRow),
          localUpdatedAt: updatedAtOf(local),
        )) {
      await upsertRemoteRow(remoteRow);
    }
  }
}

PatientLogTableSync<BloodPressureRow> bloodPressureSync(AppDatabase db) =>
    PatientLogTableSync<BloodPressureRow>(
      db: db,
      remoteTableName: 'blood_pressure_readings',
      getDirtyRows: db.bloodPressureDao.getDirtyRows,
      patientIdOf: (row) => row.patientId,
      toRemoteJson: bloodPressureRowToRemoteJson,
      fromRemoteJson: bloodPressureRowFromRemoteJson,
      idOf: (row) => row.id,
      updatedAtOf: (row) => row.updatedAt,
      getRowById: db.bloodPressureDao.getRowById,
      upsertRemoteRow: (row) =>
          db.bloodPressureDao.upsertRemoteRow(row, isDirty: false),
      markSynced: db.bloodPressureDao.markSynced,
    );

PatientLogTableSync<BloodGlucoseRow> bloodGlucoseSync(AppDatabase db) =>
    PatientLogTableSync<BloodGlucoseRow>(
      db: db,
      remoteTableName: 'blood_glucose_readings',
      getDirtyRows: db.bloodGlucoseDao.getDirtyRows,
      patientIdOf: (row) => row.patientId,
      toRemoteJson: bloodGlucoseRowToRemoteJson,
      fromRemoteJson: bloodGlucoseRowFromRemoteJson,
      idOf: (row) => row.id,
      updatedAtOf: (row) => row.updatedAt,
      getRowById: db.bloodGlucoseDao.getRowById,
      upsertRemoteRow: (row) =>
          db.bloodGlucoseDao.upsertRemoteRow(row, isDirty: false),
      markSynced: db.bloodGlucoseDao.markSynced,
    );

PatientLogTableSync<WeightRow> weightSync(AppDatabase db) =>
    PatientLogTableSync<WeightRow>(
      db: db,
      remoteTableName: 'weight_readings',
      getDirtyRows: db.weightDao.getDirtyRows,
      patientIdOf: (row) => row.patientId,
      toRemoteJson: weightRowToRemoteJson,
      fromRemoteJson: weightRowFromRemoteJson,
      idOf: (row) => row.id,
      updatedAtOf: (row) => row.updatedAt,
      getRowById: db.weightDao.getRowById,
      upsertRemoteRow: (row) =>
          db.weightDao.upsertRemoteRow(row, isDirty: false),
      markSynced: db.weightDao.markSynced,
    );

PatientLogTableSync<FluidIntakeRow> fluidIntakeSync(AppDatabase db) =>
    PatientLogTableSync<FluidIntakeRow>(
      db: db,
      remoteTableName: 'fluid_intake_logs',
      getDirtyRows: db.fluidIntakeDao.getDirtyRows,
      patientIdOf: (row) => row.patientId,
      toRemoteJson: fluidIntakeRowToRemoteJson,
      fromRemoteJson: fluidIntakeRowFromRemoteJson,
      idOf: (row) => row.id,
      updatedAtOf: (row) => row.updatedAt,
      getRowById: db.fluidIntakeDao.getRowById,
      upsertRemoteRow: (row) =>
          db.fluidIntakeDao.upsertRemoteRow(row, isDirty: false),
      markSynced: db.fluidIntakeDao.markSynced,
    );

class PatientPreferencesSync implements SyncableTable {
  PatientPreferencesSync({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  @override
  String get tableKey => remoteTableName;

  @override
  String get remoteTableName => 'patient_preferences';

  @override
  Future<void> push(SupabaseClient supabase, SyncScope scope) async {
    final dirtyRows = await _db.patientPreferencesDao.getDirtyRows();
    for (final row in dirtyRows) {
      if (!scope.canWrite(row.patientId)) {
        continue;
      }
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
        await _db.patientPreferencesDao.markSynced(
          serverRow['id'] as String,
          parseRemoteDateTime(serverRow['updated_at']),
        );
      }
    }
  }

  @override
  Future<void> pull(SupabaseClient supabase, SyncScope scope) async {
    for (final patientId in scope.patientIds) {
      await pullForPatient(
        db: _db,
        supabase: supabase,
        tableKey: tableKey,
        remoteTableName: remoteTableName,
        patientId: patientId,
        apply: _applyPulledRow,
      );
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
    if (local == null ||
        shouldApplyRemoteUpdate(
          remoteUpdatedAt: remoteRow.updatedAt,
          localUpdatedAt: local.updatedAt,
        )) {
      await _db.patientPreferencesDao.upsertRemoteRow(
        remoteRow,
        isDirty: false,
      );
    }
  }
}

class PatientMedicationScheduleSync implements SyncableTable {
  PatientMedicationScheduleSync({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  @override
  String get tableKey => remoteTableName;

  @override
  String get remoteTableName => 'patient_medication_schedules';

  @override
  Future<void> push(SupabaseClient supabase, SyncScope scope) async {
    final dirtyRows = await _db.patientMedicationScheduleDao.getDirtyRows();
    for (final row in dirtyRows) {
      if (!scope.canWrite(row.patientId)) {
        continue;
      }
      final existing = await supabase
          .from(remoteTableName)
          .select('id')
          .eq('patient_id', row.patientId)
          .maybeSingle();
      final remoteId = existing?['id'] as String?;
      var local = row;
      if (remoteId != null && remoteId != row.id) {
        await _db.patientMedicationScheduleDao.rebindId(
          oldId: row.id,
          newId: remoteId,
        );
        local = (await _db.patientMedicationScheduleDao.getRowById(remoteId))!;
      }

      final response = await supabase
          .from(remoteTableName)
          .upsert(
            patientMedicationScheduleRowToRemoteJson(local),
            onConflict: 'id',
          )
          .select();

      for (final serverRow in List<Map<String, dynamic>>.from(response)) {
        await _db.patientMedicationScheduleDao.markSynced(
          serverRow['id'] as String,
          parseRemoteDateTime(serverRow['updated_at']),
        );
      }
    }
  }

  @override
  Future<void> pull(SupabaseClient supabase, SyncScope scope) async {
    for (final patientId in scope.patientIds) {
      await pullForPatient(
        db: _db,
        supabase: supabase,
        tableKey: tableKey,
        remoteTableName: remoteTableName,
        patientId: patientId,
        apply: _applyPulledRow,
      );
    }
  }

  Future<void> _applyPulledRow(Map<String, dynamic> remote) async {
    final remoteRow = patientMedicationScheduleRowFromRemoteJson(remote);
    final localByPatient = await _db.patientMedicationScheduleDao
        .getRowByPatientId(remoteRow.patientId);

    if (localByPatient != null && localByPatient.id != remoteRow.id) {
      if (localByPatient.isDirty &&
          !shouldApplyRemoteUpdate(
            remoteUpdatedAt: remoteRow.updatedAt,
            localUpdatedAt: localByPatient.updatedAt,
          )) {
        await _db.patientMedicationScheduleDao.rebindId(
          oldId: localByPatient.id,
          newId: remoteRow.id,
        );
        return;
      }
      await _db.patientMedicationScheduleDao.deleteById(localByPatient.id);
      await _db.patientMedicationScheduleDao.upsertRemoteRow(
        remoteRow,
        isDirty: false,
      );
      return;
    }

    final local = localByPatient ??
        await _db.patientMedicationScheduleDao.getRowById(remoteRow.id);
    if (local == null ||
        shouldApplyRemoteUpdate(
          remoteUpdatedAt: remoteRow.updatedAt,
          localUpdatedAt: local.updatedAt,
        )) {
      await _db.patientMedicationScheduleDao.upsertRemoteRow(
        remoteRow,
        isDirty: false,
      );
    }
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
