import 'package:app/data/sync/sync_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldApplyRemoteUpdate', () {
    test('remote newer wins', () {
      expect(
        shouldApplyRemoteUpdate(
          remoteUpdatedAt: DateTime.utc(2026, 7, 8, 12),
          localUpdatedAt: DateTime.utc(2026, 7, 8, 11),
        ),
        isTrue,
      );
    });

    test('local newer keeps local', () {
      expect(
        shouldApplyRemoteUpdate(
          remoteUpdatedAt: DateTime.utc(2026, 7, 8, 11),
          localUpdatedAt: DateTime.utc(2026, 7, 8, 12),
        ),
        isFalse,
      );
    });

    test('equal updated_at keeps local (tie -> local wins)', () {
      final timestamp = DateTime.utc(2026, 7, 8, 12);
      expect(
        shouldApplyRemoteUpdate(
          remoteUpdatedAt: timestamp,
          localUpdatedAt: timestamp,
        ),
        isFalse,
      );
    });
  });

  group('parseRemoteDateTime', () {
    test('parses ISO string to UTC', () {
      final parsed = parseRemoteDateTime('2026-07-08T09:30:00+00:00');
      expect(parsed, DateTime.utc(2026, 7, 8, 9, 30));
    });
  });
}
