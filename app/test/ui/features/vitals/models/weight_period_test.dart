import 'package:app/domain/models/weight_reading.dart';
import 'package:app/ui/features/vitals/models/weight_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weightPeriodRange', () {
    final today = DateTime(2026, 7, 10);

    test('last7Days covers rolling 7-day window', () {
      final range = weightPeriodRange(WeightPeriod.last7Days, today);
      expect(range.start, DateTime(2026, 7, 4));
      expect(range.end, today);
    });

    test('last30Days covers rolling 30-day window', () {
      final range = weightPeriodRange(WeightPeriod.last30Days, today);
      expect(range.start, DateTime(2026, 6, 11));
      expect(range.end, today);
    });

    test('current month starts on the 1st and ends today', () {
      final range = weightPeriodRange(WeightPeriod.month, today);
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, today);
    });

    test('period labels match BP-style wording', () {
      expect(
        weightPeriodLabel(WeightPeriod.last7Days, today: today),
        'Last 7 Days',
      );
      expect(
        weightPeriodLabel(WeightPeriod.last30Days, today: today),
        'Last 30 Days',
      );
      expect(
        weightPeriodLabel(WeightPeriod.month, today: today),
        'This Month',
      );
    });
  });

  group('weightChartDays', () {
    test('buckets latest reading per local day', () {
      final days = weightChartDays(
        readings: [
          WeightReading(
            id: 'a',
            recordedAt: DateTime(2026, 7, 8, 18),
            valueKg: 72,
          ),
          WeightReading(
            id: 'b',
            recordedAt: DateTime(2026, 7, 8, 9),
            valueKg: 71,
          ),
          WeightReading(
            id: 'c',
            recordedAt: DateTime(2026, 7, 9, 10),
            valueKg: 72.5,
          ),
        ],
        start: DateTime(2026, 7, 8),
        end: DateTime(2026, 7, 10),
      );

      expect(days, hasLength(3));
      expect(days[0].valueKg, 72);
      expect(days[0].axisLabel, 'W');
      expect(days[1].valueKg, 72.5);
      expect(days[2].valueKg, isNull);
    });

    test('uses day-of-month labels for ranges longer than 7 days', () {
      final days = weightChartDays(
        readings: const [],
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 10),
      );

      expect(days.first.axisLabel, '1');
      expect(days.last.axisLabel, '10');
    });
  });

  group('weightReadingsInRange', () {
    test('filters by local calendar day', () {
      final readings = [
        WeightReading(
          id: 'new',
          recordedAt: DateTime(2026, 7, 10, 9),
          valueKg: 73,
        ),
        WeightReading(
          id: 'old',
          recordedAt: DateTime(2026, 7, 1, 9),
          valueKg: 70,
        ),
      ];
      final inRange = weightReadingsInRange(
        readings,
        DateTime(2026, 7, 6),
        DateTime(2026, 7, 10),
      );
      expect(inRange, hasLength(1));
      expect(inRange.first.id, 'new');
    });
  });
}
