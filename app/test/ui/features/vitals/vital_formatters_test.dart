import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatHistoryDateHeader', () {
    test('formats weekday, month, and day in uppercase', () {
      final date = DateTime(2026, 7, 7);
      expect(formatHistoryDateHeader(date), 'TUESDAY, JULY 7');
    });
  });

  group('formatHistoryTime', () {
    test('formats local time as HH:mm', () {
      final recordedAt = DateTime.utc(2026, 7, 7, 3, 5);
      expect(formatHistoryTime(recordedAt), recordedAt.toLocal().hour.toString().padLeft(2, '0') + ':' + recordedAt.toLocal().minute.toString().padLeft(2, '0'));
    });
  });

  group('formatTrackRecordedAt', () {
    test('uses Today label for the current date', () {
      final now = DateTime.now();
      final recordedAt = DateTime(now.year, now.month, now.day, 9, 15);
      expect(formatTrackRecordedAt(recordedAt), 'Today · 09:15');
    });
  });

  group('formatWeightHistorySubtitle', () {
    test('includes timing, time, and optional context', () {
      final subtitle = formatWeightHistorySubtitle(
        dialysisTiming: 'pre_dialysis',
        recordedAt: DateTime.utc(2026, 7, 7, 3, 30),
        weightContext: 'morning',
      );

      expect(subtitle, contains('Pre-dialysis'));
      expect(subtitle, contains('Morning'));
    });

    test('omits context when null', () {
      final subtitle = formatWeightHistorySubtitle(
        dialysisTiming: 'non_dialysis',
        recordedAt: DateTime.utc(2026, 7, 7, 3, 30),
      );

      expect(subtitle, contains('Non-dialysis day'));
      expect(subtitle, isNot(contains('Morning')));
    });
  });

  group('formatDialysisTimingLabel', () {
    test('maps known timing values', () {
      expect(formatDialysisTimingLabel('pre_dialysis'), 'Pre-dialysis');
      expect(formatDialysisTimingLabel('post_dialysis'), 'Post-dialysis');
      expect(formatDialysisTimingLabel('non_dialysis'), 'Non-dialysis day');
    });
  });

  group('formatWeightContextLabel', () {
    test('maps known context values', () {
      expect(formatWeightContextLabel('morning'), 'Morning');
      expect(formatWeightContextLabel('evening'), 'Evening');
    });
  });

  group('groupReadingsByLocalDate', () {
    test('groups readings by local calendar date newest first', () {
      final readings = [
        _Reading(DateTime.utc(2026, 7, 7, 10)),
        _Reading(DateTime.utc(2026, 7, 6, 18)),
        _Reading(DateTime.utc(2026, 7, 7, 8)),
      ];

      final grouped = groupReadingsByLocalDate(
        readings,
        (reading) => reading.recordedAt,
      );

      expect(grouped.length, 2);
      expect(grouped.keys.first, localDateOnly(readings.first.recordedAt));
      expect(grouped.values.first.length, 2);
      expect(grouped.values.last.length, 1);
    });
  });
}

class _Reading {
  _Reading(this.recordedAt);

  final DateTime recordedAt;
}
