import 'package:app/domain/models/weight_gain_from_dry_weight.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/domain/models/weight_reading_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weightGainFromDryWeightOnLocalDate', () {
    final day = DateTime(2026, 7, 10);

    WeightReading reading({
      required String id,
      required DateTime recordedAt,
      required double valueKg,
      String dialysisTiming = dialysisTimingNonDialysis,
      String? weightContext,
    }) {
      return WeightReading(
        id: id,
        recordedAt: recordedAt,
        valueKg: valueKg,
        dialysisTiming: dialysisTiming,
        weightContext: weightContext,
      );
    }

    test('returns gain from last post-dialysis to non-dialysis entry', () {
      final result = weightGainFromDryWeightOnLocalDate(
        [
          reading(
            id: 'post',
            recordedAt: DateTime(2026, 7, 8, 14),
            valueKg: 70,
            dialysisTiming: dialysisTimingPostDialysis,
          ),
          reading(
            id: 'current',
            recordedAt: DateTime(2026, 7, 10, 9),
            valueKg: 72.5,
          ),
        ],
        day,
      );

      expect(result, isNotNull);
      expect(result!.gainKg, closeTo(2.5, 0.001));
      expect(result.displayGain, '+2.5 kg');
      expect(result.postDialysis.id, 'post');
      expect(result.current.id, 'current');
    });

    test('accepts random context as current entry', () {
      final result = weightGainFromDryWeightOnLocalDate(
        [
          reading(
            id: 'post',
            recordedAt: DateTime(2026, 7, 9, 16),
            valueKg: 68,
            dialysisTiming: dialysisTimingPostDialysis,
          ),
          reading(
            id: 'random',
            recordedAt: DateTime(2026, 7, 10, 11),
            valueKg: 69.2,
            dialysisTiming: dialysisTimingPreDialysis,
            weightContext: weightContextRandom,
          ),
        ],
        day,
      );

      expect(result, isNotNull);
      expect(result!.gainKg, closeTo(1.2, 0.001));
      expect(result.current.id, 'random');
    });

    test('uses most recent post-dialysis before current', () {
      final result = weightGainFromDryWeightOnLocalDate(
        [
          reading(
            id: 'old-post',
            recordedAt: DateTime(2026, 7, 5, 14),
            valueKg: 71,
            dialysisTiming: dialysisTimingPostDialysis,
          ),
          reading(
            id: 'new-post',
            recordedAt: DateTime(2026, 7, 8, 14),
            valueKg: 70,
            dialysisTiming: dialysisTimingPostDialysis,
          ),
          reading(
            id: 'current',
            recordedAt: DateTime(2026, 7, 10, 8),
            valueKg: 71.5,
          ),
        ],
        day,
      );

      expect(result!.postDialysis.id, 'new-post');
      expect(result.gainKg, closeTo(1.5, 0.001));
    });

    test('returns null without post-dialysis baseline', () {
      final result = weightGainFromDryWeightOnLocalDate(
        [
          reading(
            id: 'current',
            recordedAt: DateTime(2026, 7, 10, 9),
            valueKg: 72,
          ),
        ],
        day,
      );

      expect(result, isNull);
    });

    test('ignores pre-dialysis without random context as current', () {
      final result = weightGainFromDryWeightOnLocalDate(
        [
          reading(
            id: 'post',
            recordedAt: DateTime(2026, 7, 8, 14),
            valueKg: 70,
            dialysisTiming: dialysisTimingPostDialysis,
          ),
          reading(
            id: 'pre',
            recordedAt: DateTime(2026, 7, 10, 8),
            valueKg: 73,
            dialysisTiming: dialysisTimingPreDialysis,
          ),
        ],
        day,
      );

      expect(result, isNull);
    });

    test('formats negative gain without plus sign', () {
      final result = weightGainFromDryWeightOnLocalDate(
        [
          reading(
            id: 'post',
            recordedAt: DateTime(2026, 7, 8, 14),
            valueKg: 72,
            dialysisTiming: dialysisTimingPostDialysis,
          ),
          reading(
            id: 'current',
            recordedAt: DateTime(2026, 7, 10, 9),
            valueKg: 71,
          ),
        ],
        day,
      );

      expect(result!.displayGain, '-1.0 kg');
    });
  });
}
