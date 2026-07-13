import 'package:app/data/local/app_database.dart';
import 'package:app/domain/models/medication.dart';

extension MedicationRowMapper on MedicationRow {
  Medication toDomain() {
    return Medication(
      id: id,
      pharmaceuticalName: pharmaceuticalName,
      composition: composition,
      about: about,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension MedicationDomainMapper on Medication {
  MedicationsCompanion toCompanion() {
    final now = DateTime.now().toUtc();
    return MedicationsCompanion.insert(
      id: id,
      pharmaceuticalName: pharmaceuticalName,
      composition: composition,
      about: about,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }
}
