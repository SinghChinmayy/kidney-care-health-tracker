import 'package:app/domain/models/patient_medication_schedule.dart';
import 'package:app/ui/features/journal/utils/dialysis_days_schedule_change.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeDialysisDaysChangeImpact', () {
    test('flags removed days that had meds', () {
      const schedule = PatientMedicationSchedule(
        id: 's1',
        patientId: 'p1',
        byDay: {
          1: ['med-a'],
          3: ['med-b'],
          5: [],
        },
      );

      final impact = computeDialysisDaysChangeImpact(
        oldDays: [1, 3, 5],
        newDays: [1, 5],
        schedule: schedule,
      );

      expect(impact.removedDays, [3]);
      expect(impact.addedDays, isEmpty);
      expect(impact.clearsAll, isFalse);
      expect(impact.needsWarning, isTrue);
    });

    test('does not warn when removed day had no meds and nothing added', () {
      const schedule = PatientMedicationSchedule(
        id: 's1',
        patientId: 'p1',
        byDay: {
          1: ['med-a'],
          5: [],
        },
      );

      final impact = computeDialysisDaysChangeImpact(
        oldDays: [1, 5],
        newDays: [1],
        schedule: schedule,
      );

      expect(impact.removedDays, isEmpty);
      expect(impact.addedDays, isEmpty);
      expect(impact.needsWarning, isFalse);
    });

    test('flags newly added days', () {
      const schedule = PatientMedicationSchedule(
        id: 's1',
        patientId: 'p1',
        byDay: {
          1: ['med-a'],
        },
      );

      final impact = computeDialysisDaysChangeImpact(
        oldDays: [1],
        newDays: [1, 3],
        schedule: schedule,
      );

      expect(impact.addedDays, [3]);
      expect(impact.needsWarning, isTrue);
    });

    test('clearsAll when new days empty and schedule has meds', () {
      const schedule = PatientMedicationSchedule(
        id: 's1',
        patientId: 'p1',
        byDay: {
          1: ['med-a'],
        },
      );

      final impact = computeDialysisDaysChangeImpact(
        oldDays: [1, 3],
        newDays: [],
        schedule: schedule,
      );

      expect(impact.clearsAll, isTrue);
      expect(impact.needsWarning, isTrue);
    });
  });
}
