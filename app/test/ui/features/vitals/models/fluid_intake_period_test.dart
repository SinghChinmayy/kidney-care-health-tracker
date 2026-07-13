import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:app/ui/features/vitals/models/fluid_intake_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fluidIntakePeriodRange', () {
    final today = DateTime(2026, 7, 10);

    test('last7Days covers rolling 7-day window', () {
      final range = fluidIntakePeriodRange(FluidIntakePeriod.last7Days, today);
      expect(range.start, DateTime(2026, 7, 4));
      expect(range.end, today);
    });

    test('last30Days covers rolling 30-day window', () {
      final range = fluidIntakePeriodRange(FluidIntakePeriod.last30Days, today);
      expect(range.start, DateTime(2026, 6, 11));
      expect(range.end, today);
    });

    test('current month starts on the 1st and ends today', () {
      final range = fluidIntakePeriodRange(FluidIntakePeriod.month, today);
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, today);
    });

    test('period labels match vitals wording', () {
      expect(
        fluidIntakePeriodLabel(FluidIntakePeriod.last7Days, today: today),
        'Last 7 Days',
      );
      expect(
        fluidIntakePeriodLabel(FluidIntakePeriod.last30Days, today: today),
        'Last 30 Days',
      );
      expect(
        fluidIntakePeriodLabel(FluidIntakePeriod.month, today: today),
        'This Month',
      );
    });
  });

  group('fluidIntakeChartDays', () {
    test('sums logs per local day', () {
      final days = fluidIntakeChartDays(
        logs: [
          FluidIntakeLog(
            id: 'a',
            recordedAt: DateTime(2026, 7, 8, 9),
            fluidMl: 200,
          ),
          FluidIntakeLog(
            id: 'b',
            recordedAt: DateTime(2026, 7, 8, 18),
            fluidMl: 300,
          ),
          FluidIntakeLog(
            id: 'c',
            recordedAt: DateTime(2026, 7, 9, 10),
            fluidMl: 250,
          ),
        ],
        start: DateTime(2026, 7, 8),
        end: DateTime(2026, 7, 10),
      );

      expect(days, hasLength(3));
      expect(days[0].totalMl, 500);
      expect(days[0].axisLabel, 'W');
      expect(days[1].totalMl, 250);
      expect(days[2].totalMl, isNull);
    });

    test('uses day-of-month labels for ranges longer than 7 days', () {
      final days = fluidIntakeChartDays(
        logs: const [],
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 10),
      );

      expect(days.first.axisLabel, '1');
      expect(days.last.axisLabel, '10');
    });
  });
}
