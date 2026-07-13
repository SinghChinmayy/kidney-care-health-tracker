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

    test('compact labels are short for summary captions', () {
      expect(formatCompactDialysisTimingLabel('pre_dialysis'), 'Pre');
      expect(formatCompactDialysisTimingLabel('post_dialysis'), 'Post');
      expect(formatCompactDialysisTimingLabel('non_dialysis'), 'Off');
    });
  });

  group('formatWeightContextLabel', () {
    test('maps known context values', () {
      expect(formatWeightContextLabel('morning'), 'Morning');
      expect(formatWeightContextLabel('evening'), 'Evening');
    });

    test('compact labels are short for summary captions', () {
      expect(formatCompactWeightContextLabel('morning'), 'AM');
      expect(formatCompactWeightContextLabel('evening'), 'PM');
    });
  });

  group('formatHomeDateLabel', () {
    test('formats short weekday, month, and day', () {
      expect(formatHomeDateLabel(DateTime(2026, 1, 20)), 'Tue, Jan 20');
    });
  });

  group('recordedAtFromSelectedDate', () {
    test('uses selected day with current local time', () {
      final selectedDate = DateTime(2026, 1, 20);
      final recordedAt = recordedAtFromSelectedDate(selectedDate);
      final now = DateTime.now();

      expect(recordedAt.year, 2026);
      expect(recordedAt.month, 1);
      expect(recordedAt.day, 20);
      expect(recordedAt.hour, now.hour);
      expect(recordedAt.minute, now.minute);
    });
  });

  group('latestReadingOnLocalDate', () {
    test('returns latest reading for the requested local date', () {
      final readings = [
        _Reading(DateTime.utc(2026, 7, 7, 8)),
        _Reading(DateTime.utc(2026, 7, 7, 18)),
        _Reading(DateTime.utc(2026, 7, 6, 18)),
      ];
      final date = localDateOnly(readings[0].recordedAt);

      final latest = latestReadingOnLocalDate(
        readings,
        date,
        (reading) => reading.recordedAt,
      );

      expect(latest?.recordedAt, readings[1].recordedAt);
    });

    test('returns null when no readings match the date', () {
      final latest = latestReadingOnLocalDate(
        [_Reading(DateTime.utc(2026, 7, 7, 8))],
        DateTime(2026, 7, 8),
        (reading) => reading.recordedAt,
      );

      expect(latest, isNull);
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

  group('weekStartForLocalDate', () {
    test('returns Monday for a mid-week date', () {
      final wednesday = DateTime(2026, 7, 8);
      expect(weekStartForLocalDate(wednesday), DateTime(2026, 7, 6));
    });
  });

  group('formatWeekGroupLabel', () {
    test('uses This Week and Last Week labels', () {
      final today = localDateOnly(DateTime.now());
      final thisWeek = weekStartForLocalDate(today);
      final lastWeek = DateTime(
        thisWeek.year,
        thisWeek.month,
        thisWeek.day - 7,
      );

      expect(formatWeekGroupLabel(thisWeek), 'This Week');
      expect(formatWeekGroupLabel(lastWeek), 'Last Week');
    });

    test('formats older weeks as a date range', () {
      expect(
        formatWeekGroupLabel(DateTime(2026, 6, 2)),
        'Jun 2–8',
      );
    });
  });

  group('groupReadingsByWeekStart', () {
    test('groups readings by week newest first', () {
      final readings = [
        _Reading(DateTime(2026, 7, 8)),
        _Reading(DateTime(2026, 7, 1)),
        _Reading(DateTime(2026, 6, 30)),
      ];

      final grouped = groupReadingsByWeekStart(
        readings,
        (reading) => reading.recordedAt,
      );

      expect(grouped.length, 2);
      expect(grouped.keys.first, weekStartForLocalDate(readings.first.recordedAt));
      expect(grouped.values.first.length, 1);
      expect(grouped.values.last.length, 2);
    });
  });
}

class _Reading {
  _Reading(this.recordedAt);

  final DateTime recordedAt;
}
