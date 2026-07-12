import 'package:app/domain/models/weight_reading.dart';
import 'package:app/ui/features/vitals/models/weight_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weightPeriodRange', () {
    final today = DateTime(2026, 7, 10); // Friday

    test('week starts on Monday of current week', () {
      final range = weightPeriodRange(WeightPeriod.week, today);
      expect(range.start, DateTime(2026, 7, 6));
      expect(range.end, DateTime(2026, 7, 10));
    });

    test('past week uses full Monday–Sunday range', () {
      final range = weightPeriodRange(
        WeightPeriod.week,
        today,
        weekStart: DateTime(2026, 6, 29),
      );
      expect(range.start, DateTime(2026, 6, 29));
      expect(range.end, DateTime(2026, 7, 5));
    });

    test('week label shows range for past weeks', () {
      expect(
        weightPeriodLabel(
          WeightPeriod.week,
          weekStart: DateTime(2026, 6, 29),
          today: today,
        ),
        'Jun 29 – Jul 5',
      );
      expect(
        weightPeriodLabel(
          WeightPeriod.week,
          weekStart: DateTime(2026, 7, 6),
          today: today,
        ),
        'This Week',
      );
    });

    test('current month starts on the 1st and ends today', () {
      final range = weightPeriodRange(WeightPeriod.month, today);
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, today);
    });

    test('past month uses full calendar month', () {
      final range = weightPeriodRange(
        WeightPeriod.month,
        today,
        monthStart: DateTime(2026, 6, 1),
      );
      expect(range.start, DateTime(2026, 6, 1));
      expect(range.end, DateTime(2026, 6, 30));
    });

    test('month label shows This Month or month name', () {
      expect(
        weightPeriodLabel(
          WeightPeriod.month,
          monthStart: DateTime(2026, 7, 1),
          today: today,
        ),
        'This Month',
      );
      expect(
        weightPeriodLabel(
          WeightPeriod.month,
          monthStart: DateTime(2026, 6, 1),
          today: today,
        ),
        'Jun',
      );
    });

    test('current year starts Jan 1 and ends today', () {
      final range = weightPeriodRange(WeightPeriod.year, today);
      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, today);
    });

    test('past year uses full calendar year', () {
      final range = weightPeriodRange(
        WeightPeriod.year,
        today,
        yearStart: DateTime(2025, 1, 1),
      );
      expect(range.start, DateTime(2025, 1, 1));
      expect(range.end, DateTime(2025, 12, 31));
    });

    test('year label shows This Year or year number', () {
      expect(
        weightPeriodLabel(
          WeightPeriod.year,
          yearStart: DateTime(2026, 1, 1),
          today: today,
        ),
        'This Year',
      );
      expect(
        weightPeriodLabel(
          WeightPeriod.year,
          yearStart: DateTime(2025, 1, 1),
          today: today,
        ),
        '2025',
      );
    });

    test('all uses earliest reading through today', () {
      final range = weightPeriodRange(
        WeightPeriod.all,
        today,
        earliestReadingAt: DateTime(2026, 7, 1, 8),
      );
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, today);
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
  });

  group('weightChartMonths', () {
    test('buckets latest reading per calendar month with month letters', () {
      final months = weightChartMonths(
        readings: [
          WeightReading(
            id: 'jan',
            recordedAt: DateTime(2026, 1, 5),
            valueKg: 70,
          ),
          WeightReading(
            id: 'mar-early',
            recordedAt: DateTime(2026, 3, 2),
            valueKg: 71,
          ),
          WeightReading(
            id: 'mar-late',
            recordedAt: DateTime(2026, 3, 20),
            valueKg: 72,
          ),
        ],
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 3, 31),
      );

      expect(months, hasLength(3));
      expect(months.map((m) => m.axisLabel).toList(), ['J', 'F', 'M']);
      expect(months[0].valueKg, 70);
      expect(months[1].valueKg, isNull);
      expect(months[2].valueKg, 72);
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
