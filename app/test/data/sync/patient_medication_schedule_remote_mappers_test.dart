import 'package:app/data/sync/remote_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('patient medication schedule remote mappers', () {
    test('round-trips schedule jsonb', () {
      final row = patientMedicationScheduleRowFromRemoteJson({
        'id': 'sched-1',
        'patient_id': 'patient-1',
        'schedule': {
          'by_day': {
            '1': ['med-a', 'med-b'],
            '5': ['med-c'],
          },
        },
        'created_at': '2026-07-14T08:00:00Z',
        'updated_at': '2026-07-14T09:00:00Z',
      });

      expect(row.id, 'sched-1');
      expect(row.patientId, 'patient-1');
      expect(row.schedule[1], ['med-a', 'med-b']);
      expect(row.schedule[5], ['med-c']);
      expect(row.isDirty, isFalse);

      final json = patientMedicationScheduleRowToRemoteJson(row);
      expect(json['id'], 'sched-1');
      expect(json['patient_id'], 'patient-1');
      expect(json['schedule'], isA<Map<String, dynamic>>());
      final schedule = json['schedule'] as Map<String, dynamic>;
      final byDay = schedule['by_day'] as Map<String, dynamic>;
      expect(byDay['1'], ['med-a', 'med-b']);
      expect(byDay['5'], ['med-c']);
    });

    test('defaults empty schedule when missing', () {
      final row = patientMedicationScheduleRowFromRemoteJson({
        'id': 'sched-2',
        'patient_id': 'patient-2',
        'created_at': '2026-07-14T08:00:00Z',
        'updated_at': '2026-07-14T08:00:00Z',
      });

      expect(row.schedule, isEmpty);
    });
  });
}
