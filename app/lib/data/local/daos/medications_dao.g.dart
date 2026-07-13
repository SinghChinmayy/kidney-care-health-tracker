// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medications_dao.dart';

// ignore_for_file: type=lint
mixin _$MedicationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $MedicationsTable get medications => attachedDatabase.medications;
  MedicationsDaoManager get managers => MedicationsDaoManager(this);
}

class MedicationsDaoManager {
  final _$MedicationsDaoMixin _db;
  MedicationsDaoManager(this._db);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db.attachedDatabase, _db.medications);
}
