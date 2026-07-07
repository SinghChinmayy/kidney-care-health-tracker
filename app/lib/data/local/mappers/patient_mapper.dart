import 'package:app/data/local/app_database.dart';
import 'package:app/domain/models/patient.dart';
import 'package:drift/drift.dart';

extension PatientRowMapper on PatientRow {
  Patient toDomain() {
    return Patient(
      id: id,
      authUserId: authUserId,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      sex: sex,
      ckdStage: ckdStage,
      dialysisType: dialysisType,
      heightCm: heightCm,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension PatientDomainMapper on Patient {
  PatientsCompanion toCompanion({required bool isDirty}) {
    final now = DateTime.now().toUtc();
    return PatientsCompanion.insert(
      id: id,
      authUserId: authUserId,
      firstName: Value(firstName),
      lastName: Value(lastName),
      dateOfBirth: Value(dateOfBirth),
      sex: Value(sex),
      ckdStage: Value(ckdStage),
      dialysisType: Value(dialysisType),
      heightCm: Value(heightCm),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      deletedAt: Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }
}
