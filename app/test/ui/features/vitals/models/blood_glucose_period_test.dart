import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/ui/features/vitals/models/blood_glucose_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bloodGlucosePeriodRange', () {
    final today = DateTime(2026, 7, 10); // Friday

    test('week starts on Monday of current week', () {
      final range = bloodGlucosePeriodRange(BloodGlucosePeriod.week, today);
      expect(range.start, DateTime(2026, 7, 6));
      expect(range.end, DateTime(2026, 7, 10));
    });

    test('past week uses full Monday–Sunday range', () {
      final range = bloodGlucosePeriodRange(
        BloodGlucosePeriod.week,
        today,
        weekStart: DateTime(2026, 6, 29),
      );
      expect(range.start, DateTime(2026, 6, 29));
      expect(range.end, DateTime(2026, 7, 5));
    });

    test('week label shows range for past weeks', () {
      expect(
        bloodGlucosePeriodLabel(
          BloodGlucosePeriod.week,
          weekStart: DateTime(2026, 6, 29),
          today: today,
        ),
        'Jun 29 – Jul 5',
      );
      expect(
        bloodGlucosePeriodLabel(
          BloodGlucosePeriod.week,
          weekStart: DateTime(2026, 7, 6),
          today: today,
        ),
        'This Week',
      );
    });

    test('current month starts on the 1st and ends today', () {
      final range = bloodGlucosePeriodRange(BloodGlucosePeriod.month, today);
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, today);
    });

    test('all uses earliest reading through today', () {
      final range = bloodGlucosePeriodRange(
        BloodGlucosePeriod.all,
        today,
        earliestReadingAt: DateTime(2026, 7, 1, 8),
      );
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, today);
    });
  });

  group('bloodGlucoseChartDays', () {
    test('buckets latest reading per local day', () {
      final days = bloodGlucoseChartDays(
        readings: [
          BloodGlucoseReading(
            id: 'a',
            recordedAt: DateTime(2026, 7, 8, 18),
            valueMgDl: 140,
          ),
          BloodGlucoseReading(
            id: 'b',
            recordedAt: DateTime(2026, 7, 8, 9),
            valueMgDl: 110,
          ),
          BloodGlucoseReading(
            id: 'c',
            recordedAt: DateTime(2026, 7, 9, 10),
            valueMgDl: 125,
          ),
        ],
        start: DateTime(2026, 7, 8),
        end: DateTime(2026, 7, 10),
      );

      expect(days, hasLength(3));
      expect(days[0].valueMgDl, 140);
      expect(days[0].axisLabel, 'W');
      expect(days[1].valueMgDl, 125);
      expect(days[2].valueMgDl, isNull);
    });
  });

  group('bloodGlucoseReadingsInRange', () {
    test('filters by local calendar day', () {
      final readings = [
        BloodGlucoseReading(
          id: 'new',
          recordedAt: DateTime(2026, 7, 10, 9),
          valueMgDl: 130,
        ),
        BloodGlucoseReading(
          id: 'old',
          recordedAt: DateTime(2026, 7, 1, 9),
          valueMgDl: 100,
        ),
      ];
      final inRange = bloodGlucoseReadingsInRange(
        readings,
        DateTime(2026, 7, 6),
        DateTime(2026, 7, 10),
      );
      expect(inRange, hasLength(1));
      expect(inRange.first.id, 'new');
    });
  });
}
