import 'dart:io';

import 'package:app/data/local/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens a database whose on-disk schema is the v7 layout captured in
/// `fixtures/schema_v7.sql`, so [AppDatabase.migration] runs for real.
AppDatabase openV7Database({String seedSql = ''}) {
  final schema = File('test/data/local/fixtures/schema_v7.sql').readAsStringSync();
  return AppDatabase.forTesting(
    NativeDatabase.memory(
      setup: (raw) {
        raw.execute(schema);
        if (seedSql.isNotEmpty) {
          raw.execute(seedSql);
        }
        raw.userVersion = 7;
      },
    ),
  );
}

const _v7Seed = '''
INSERT INTO patients (id, auth_user_id, created_at, updated_at, is_dirty)
  VALUES ('patient-1', 'auth-1', 0, 0, 0);
INSERT INTO blood_pressure_readings
  (id, patient_id, recorded_at, systolic, diastolic, created_at, updated_at, is_dirty)
  VALUES ('bp-1', 'patient-1', 0, 120, 80, 0, 0, 0);
''';

void main() {
  test('upgrade from v7 keeps existing BP rows and adds context columns',
      () async {
    final db = openV7Database(seedSql: _v7Seed);
    addTearDown(db.close);

    final rows = await db.select(db.bloodPressureReadings).get();
    expect(rows, hasLength(1));
    expect(rows.single.systolic, 120);
    expect(rows.single.arm, isNull);
    expect(rows.single.posture, isNull);
    expect(rows.single.isDialysisDay, isNull);
    expect(rows.single.dialysisPhase, isNull);

    await db.into(db.bloodPressureReadings).insert(
          BloodPressureReadingsCompanion.insert(
            id: 'bp-2',
            patientId: 'patient-1',
            recordedAt: DateTime.utc(2026),
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            arm: const Value('left'),
            isDialysisDay: const Value(true),
            dialysisPhase: const Value('pre_dialysis'),
          ),
        );
    final inserted = await (db.select(db.bloodPressureReadings)
          ..where((t) => t.id.equals('bp-2')))
        .getSingle();
    expect(inserted.arm, 'left');
    expect(inserted.dialysisPhase, 'pre_dialysis');
  });

  test('upgrade from v7 adds blood group and recorded_by columns', () async {
    final db = openV7Database(seedSql: _v7Seed);
    addTearDown(db.close);

    final patient = await (db.select(db.patients)).getSingle();
    expect(patient.bloodGroup, isNull);
    final bp = await (db.select(db.bloodPressureReadings)).getSingle();
    expect(bp.recordedBy, isNull);

    for (final table in [
      'blood_glucose_readings',
      'weight_readings',
      'fluid_intake_logs',
    ]) {
      final columns = await db
          .customSelect('SELECT name FROM pragma_table_info(?)',
              variables: [Variable.withString(table)])
          .map((row) => row.read<String>('name'))
          .get();
      expect(columns, contains('recorded_by'), reason: table);
    }
  });

  test('fresh database reports the current schema version', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final version =
        await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), db.schemaVersion);
  });
}
