import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/ui/features/vitals/models/blood_pressure_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bloodPressurePeriodRange', () {
    final today = DateTime(2026, 7, 10); // Friday

    test('week starts on Monday of current week', () {
      final range = bloodPressurePeriodRange(BloodPressurePeriod.week, today);
      expect(range.start, DateTime(2026, 7, 6));
      expect(range.end, DateTime(2026, 7, 10));
    });

    test('past week uses full Monday–Sunday range', () {
      final range = bloodPressurePeriodRange(
        BloodPressurePeriod.week,
        today,
        weekStart: DateTime(2026, 6, 29),
      );
      expect(range.start, DateTime(2026, 6, 29));
      expect(range.end, DateTime(2026, 7, 5));
    });

    test('week label shows range for past weeks', () {
      expect(
        bloodPressurePeriodLabel(
          BloodPressurePeriod.week,
          weekStart: DateTime(2026, 6, 29),
          today: today,
        ),
        'Jun 29 – Jul 5',
      );
      expect(
        bloodPressurePeriodLabel(
          BloodPressurePeriod.week,
          weekStart: DateTime(2026, 7, 6),
          today: today,
        ),
        'This Week',
      );
    });

    test('current month starts on the 1st and ends today', () {
      final range = bloodPressurePeriodRange(BloodPressurePeriod.month, today);
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, today);
    });

    test('all uses earliest reading through today', () {
      final range = bloodPressurePeriodRange(
        BloodPressurePeriod.all,
        today,
        earliestReadingAt: DateTime(2026, 7, 1, 8),
      );
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, today);
    });
  });

  group('bloodPressureChartDays', () {
    test('buckets latest systolic per local day', () {
      final days = bloodPressureChartDays(
        readings: [
          BloodPressureReading(
            id: 'a',
            recordedAt: DateTime(2026, 7, 8, 18),
            systolic: 140,
            diastolic: 90,
          ),
          BloodPressureReading(
            id: 'b',
            recordedAt: DateTime(2026, 7, 8, 9),
            systolic: 110,
            diastolic: 70,
          ),
          BloodPressureReading(
            id: 'c',
            recordedAt: DateTime(2026, 7, 9, 10),
            systolic: 125,
            diastolic: 80,
          ),
        ],
        start: DateTime(2026, 7, 8),
        end: DateTime(2026, 7, 10),
      );

      expect(days, hasLength(3));
      expect(days[0].systolic, 140);
      expect(days[0].axisLabel, 'W');
      expect(days[1].systolic, 125);
      expect(days[2].systolic, isNull);
    });
  });

  group('bloodPressureReadingsInRange', () {
    test('filters by local calendar day', () {
      final readings = [
        BloodPressureReading(
          id: 'new',
          recordedAt: DateTime(2026, 7, 10, 9),
          systolic: 130,
          diastolic: 80,
        ),
        BloodPressureReading(
          id: 'old',
          recordedAt: DateTime(2026, 7, 1, 9),
          systolic: 100,
          diastolic: 70,
        ),
      ];
      final inRange = bloodPressureReadingsInRange(
        readings,
        DateTime(2026, 7, 6),
        DateTime(2026, 7, 10),
      );
      expect(inRange, hasLength(1));
      expect(inRange.first.id, 'new');
    });
  });
}
