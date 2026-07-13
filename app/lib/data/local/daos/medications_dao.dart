import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/mappers/medication_mapper.dart';
import 'package:app/data/local/tables/medications.dart';
import 'package:app/domain/models/medication.dart';
import 'package:drift/drift.dart';

part 'medications_dao.g.dart';

@DriftAccessor(tables: [Medications])
class MedicationsDao extends DatabaseAccessor<AppDatabase>
    with _$MedicationsDaoMixin {
  MedicationsDao(super.db);

  Future<int> countAll() {
    final countExp = medications.id.count();
    final query = selectOnly(medications)..addColumns([countExp]);
    return query.map((row) => row.read(countExp) ?? 0).getSingle();
  }

  Future<List<Medication>> getAll() async {
    final rows = await (select(medications)
          ..orderBy([(t) => OrderingTerm.asc(t.pharmaceuticalName)]))
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Future<Medication?> getById(String id) async {
    final row = await (select(medications)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  Future<void> upsertAll(List<Medication> items) async {
    await batch((batch) {
      for (final item in items) {
        batch.insert(
          medications,
          item.toCompanion(),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> insert(Medication medication) {
    return into(medications).insert(medication.toCompanion());
  }
}
