import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/domain/models/patient_medication_schedule.dart';
import 'package:uuid/uuid.dart';

class PatientMedicationScheduleRepository {
  PatientMedicationScheduleRepository({
    required AppDatabase db,
    required PatientRepository patientRepository,
    required String? Function() currentAuthUserId,
    void Function()? onWrite,
  })  : _db = db,
        _patientRepository = patientRepository,
        _currentAuthUserId = currentAuthUserId,
        _onWrite = onWrite ?? (() {});

  final AppDatabase _db;
  final PatientRepository _patientRepository;
  final String? Function() _currentAuthUserId;
  final void Function() _onWrite;
  static const _uuid = Uuid();

  Future<String?> _patientIdOrNull() async {
    final authUserId = _currentAuthUserId();
    if (authUserId == null) {
      return null;
    }
    final patient =
        await _patientRepository.getPatientForAuthUser(authUserId);
    return patient?.id;
  }

  Future<PatientMedicationSchedule?> getOrCreateForCurrentPatient() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      return null;
    }
    final existing =
        await _db.patientMedicationScheduleDao.getActiveByPatientId(patientId);
    if (existing != null) {
      return existing;
    }

    final now = DateTime.now().toUtc();
    final seeded = PatientMedicationSchedule(
      id: _uuid.v4(),
      patientId: patientId,
      byDay: const {},
      createdAt: now,
      updatedAt: now,
    );
    await _db.patientMedicationScheduleDao.insertSchedule(
      seeded,
      isDirty: true,
    );
    _onWrite();
    return seeded;
  }

  Future<PatientMedicationSchedule?> getForCurrentPatient() async {
    final patientId = await _patientIdOrNull();
    if (patientId == null) {
      return null;
    }
    return _db.patientMedicationScheduleDao.getActiveByPatientId(patientId);
  }

  Future<void> save(PatientMedicationSchedule schedule) async {
    final now = DateTime.now().toUtc();
    final updated = schedule.copyWith(updatedAt: now);
    final existing =
        await _db.patientMedicationScheduleDao.getRowById(schedule.id);
    if (existing == null) {
      await _db.patientMedicationScheduleDao.insertSchedule(
        updated,
        isDirty: true,
      );
    } else {
      await _db.patientMedicationScheduleDao.updateSchedule(
        updated,
        isDirty: true,
      );
    }
    _onWrite();
  }

  /// Applies dialysis-day change: drop removed days, ensure new days exist as empty.
  Future<PatientMedicationSchedule?> applyDialysisDaysChange({
    required List<int> newDays,
  }) async {
    final schedule = await getOrCreateForCurrentPatient();
    if (schedule == null) {
      return null;
    }

    final next = <int, List<String>>{};
    for (final day in newDays) {
      next[day] = List<String>.from(schedule.byDay[day] ?? const []);
    }

    final updated = schedule.copyWith(
      byDay: next,
      updatedAt: DateTime.now().toUtc(),
    );
    await save(updated);
    return updated;
  }

  Future<PatientMedicationSchedule?> addMedToDay({
    required int isoWeekday,
    required String medicationId,
  }) async {
    final schedule = await getOrCreateForCurrentPatient();
    if (schedule == null) {
      return null;
    }
    final ids = List<String>.from(schedule.byDay[isoWeekday] ?? const []);
    if (ids.contains(medicationId)) {
      return schedule;
    }
    ids.add(medicationId);
    final next = Map<int, List<String>>.from(schedule.byDay)
      ..[isoWeekday] = ids;
    final updated = schedule.copyWith(
      byDay: next,
      updatedAt: DateTime.now().toUtc(),
    );
    await save(updated);
    return updated;
  }

  Future<PatientMedicationSchedule?> removeMedFromDay({
    required int isoWeekday,
    required String medicationId,
  }) async {
    final schedule = await getOrCreateForCurrentPatient();
    if (schedule == null) {
      return null;
    }
    final ids = List<String>.from(schedule.byDay[isoWeekday] ?? const [])
      ..remove(medicationId);
    final next = Map<int, List<String>>.from(schedule.byDay)
      ..[isoWeekday] = ids;
    final updated = schedule.copyWith(
      byDay: next,
      updatedAt: DateTime.now().toUtc(),
    );
    await save(updated);
    return updated;
  }

  Future<PatientMedicationSchedule?> replaceMedOnDay({
    required int isoWeekday,
    required String oldMedicationId,
    required String newMedicationId,
  }) async {
    final schedule = await getOrCreateForCurrentPatient();
    if (schedule == null) {
      return null;
    }
    final ids = List<String>.from(schedule.byDay[isoWeekday] ?? const []);
    final index = ids.indexOf(oldMedicationId);
    if (index < 0) {
      return schedule;
    }
    if (newMedicationId != oldMedicationId && ids.contains(newMedicationId)) {
      ids.removeAt(index);
    } else {
      ids[index] = newMedicationId;
    }
    final next = Map<int, List<String>>.from(schedule.byDay)
      ..[isoWeekday] = ids;
    final updated = schedule.copyWith(
      byDay: next,
      updatedAt: DateTime.now().toUtc(),
    );
    await save(updated);
    return updated;
  }
}
