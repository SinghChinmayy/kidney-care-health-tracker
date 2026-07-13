import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/ui/features/vitals/models/blood_pressure_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bloodPressurePeriodRange', () {
    final today = DateTime(2026, 7, 10); // Friday

    test('last7Days starts 6 days ago and ends today', () {
      final range = bloodPressurePeriodRange(BloodPressurePeriod.last7Days, today);
      expect(range.start, DateTime(2026, 7, 4));
      expect(range.end, DateTime(2026, 7, 10));
    });

    test('last30Days starts 29 days ago and ends today', () {
      final range = bloodPressurePeriodRange(BloodPressurePeriod.last30Days, today);
      expect(range.start, DateTime(2026, 6, 11));
      expect(range.end, DateTime(2026, 7, 10));
    });

    test('month starts on the 1st of month and ends today', () {
      final range = bloodPressurePeriodRange(BloodPressurePeriod.month, today);
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, DateTime(2026, 7, 10));
    });
  });

  group('bloodPressurePeriodLabel', () {
    final today = DateTime(2026, 7, 10);

    test('last7Days shows correct label', () {
      expect(
        bloodPressurePeriodLabel(BloodPressurePeriod.last7Days, today: today),
        'Last 7 Days',
      );
    });

    test('last30Days shows correct label', () {
      expect(
        bloodPressurePeriodLabel(BloodPressurePeriod.last30Days, today: today),
        'Last 30 Days',
      );
    });

    test('month shows correct label', () {
      expect(
        bloodPressurePeriodLabel(
          BloodPressurePeriod.month,
          monthStart: DateTime(2026, 7, 1),
          today: today,
        ),
        'This Month',
      );
      expect(
        bloodPressurePeriodLabel(
          BloodPressurePeriod.month,
          monthStart: DateTime(2026, 6, 1),
          today: today,
        ),
        'Jun',
      );
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
}
