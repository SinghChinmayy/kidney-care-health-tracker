import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/ui/features/vitals/models/blood_glucose_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bloodGlucosePeriodRange', () {
    final today = DateTime(2026, 7, 10);

    test('last7Days covers rolling 7-day window', () {
      final range =
          bloodGlucosePeriodRange(BloodGlucosePeriod.last7Days, today);
      expect(range.start, DateTime(2026, 7, 4));
      expect(range.end, today);
    });

    test('last30Days covers rolling 30-day window', () {
      final range =
          bloodGlucosePeriodRange(BloodGlucosePeriod.last30Days, today);
      expect(range.start, DateTime(2026, 6, 11));
      expect(range.end, today);
    });

    test('current month starts on the 1st and ends today', () {
      final range = bloodGlucosePeriodRange(BloodGlucosePeriod.month, today);
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, today);
    });

    test('period labels match BP-style wording', () {
      expect(
        bloodGlucosePeriodLabel(BloodGlucosePeriod.last7Days, today: today),
        'Last 7 Days',
      );
      expect(
        bloodGlucosePeriodLabel(BloodGlucosePeriod.last30Days, today: today),
        'Last 30 Days',
      );
      expect(
        bloodGlucosePeriodLabel(BloodGlucosePeriod.month, today: today),
        'This Month',
      );
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

    test('uses day-of-month labels for ranges longer than 7 days', () {
      final days = bloodGlucoseChartDays(
        readings: const [],
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 10),
      );

      expect(days.first.axisLabel, '1');
      expect(days.last.axisLabel, '10');
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
