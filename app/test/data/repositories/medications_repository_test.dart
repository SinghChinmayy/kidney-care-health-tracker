import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/medication_seed.dart';
import 'package:app/data/repositories/medications_repository.dart';
import 'package:app/domain/models/medication.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MedicationsRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = MedicationsRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('ensureSeeded inserts seed catalog once', () async {
    final first = await repository.getAll();
    expect(first, isNotEmpty);
    expect(first.length, medicationSeedData().length);

    final second = await repository.getAll();
    expect(second.length, first.length);
  });

  test('add inserts custom medication', () async {
    await repository.ensureSeeded();
    final before = (await repository.getAll()).length;
    final now = DateTime.utc(2026, 7, 14);

    await repository.add(
      Medication(
        id: 'custom-1',
        pharmaceuticalName: 'Custom Med',
        composition: 'X 5mg',
        about: 'User entry',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final all = await repository.getAll();
    expect(all.length, before + 1);
    expect(
      all.any((m) => m.id == 'custom-1' && m.pharmaceuticalName == 'Custom Med'),
      isTrue,
    );
  });

  test('getById returns seeded medication', () async {
    final med = await repository.getById('med-furosemide');
    expect(med, isNotNull);
    expect(med!.pharmaceuticalName, 'Furosemide');
  });
}
