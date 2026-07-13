import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/medication_seed.dart';
import 'package:app/domain/models/medication.dart';

class MedicationsRepository {
  MedicationsRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;
  bool _seedEnsured = false;

  Future<void> ensureSeeded() async {
    if (_seedEnsured) {
      return;
    }
    final count = await _db.medicationsDao.countAll();
    if (count == 0) {
      await _db.medicationsDao.upsertAll(medicationSeedData());
    }
    _seedEnsured = true;
  }

  Future<List<Medication>> getAll() async {
    await ensureSeeded();
    return _db.medicationsDao.getAll();
  }

  Future<Medication?> getById(String id) async {
    await ensureSeeded();
    return _db.medicationsDao.getById(id);
  }

  Future<void> add(Medication medication) async {
    await ensureSeeded();
    await _db.medicationsDao.insert(medication);
  }
}
