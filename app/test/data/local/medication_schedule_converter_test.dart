import 'package:app/data/local/converters/medication_schedule_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedicationScheduleConverter', () {
    const converter = MedicationScheduleConverter();

    test('round-trips by_day map', () {
      final original = {
        1: ['med-a', 'med-b'],
        5: ['med-c'],
      };

      final sql = converter.toSql(original);
      final restored = converter.fromSql(sql);

      expect(restored[1], ['med-a', 'med-b']);
      expect(restored[5], ['med-c']);
      expect(restored.keys, [1, 5]);
    });

    test('toSql wraps keys as strings under by_day', () {
      final sql = converter.toSql({
        3: ['med-x'],
      });
      expect(sql, contains('"by_day"'));
      expect(sql, contains('"3"'));
      expect(sql, contains('med-x'));
    });

    test('fromSql ignores invalid weekdays and duplicate ids', () {
      final restored = converter.fromSql(
        '{"by_day":{"0":["bad"],"1":["a","a","b"],"8":["also-bad"]}}',
      );
      expect(restored.keys, [1]);
      expect(restored[1], ['a', 'b']);
    });

    test('parseMedicationSchedule accepts Map and JSON string', () {
      final fromMap = parseMedicationSchedule({
        'by_day': {
          '2': ['m1'],
        },
      });
      final fromString = parseMedicationSchedule('{"by_day":{"2":["m1"]}}');

      expect(fromMap[2], ['m1']);
      expect(fromString[2], ['m1']);
    });

    test('parseMedicationSchedule returns empty for null/invalid', () {
      expect(parseMedicationSchedule(null), isEmpty);
      expect(parseMedicationSchedule(''), isEmpty);
      expect(parseMedicationSchedule([]), isEmpty);
    });
  });
}
