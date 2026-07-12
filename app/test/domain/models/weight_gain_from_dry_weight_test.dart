import 'package:app/domain/models/weight_gain_from_dry_weight.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/domain/models/weight_reading_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weightGainSnapshotOnLocalDate', () {
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

    test('returns paired gain from last post-dialysis to non-dialysis entry',
        () {
      final result = weightGainSnapshotOnLocalDate(
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

      expect(result.status, WeightGainStatus.paired);
      expect(result.gainKg, closeTo(2.5, 0.001));
      expect(result.displayGain, '+2.5 kg');
      expect(result.postDialysis!.id, 'post');
      expect(result.current!.id, 'current');
    });

    test('accepts random context as current entry', () {
      final result = weightGainSnapshotOnLocalDate(
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

      expect(result.status, WeightGainStatus.paired);
      expect(result.gainKg, closeTo(1.2, 0.001));
      expect(result.current!.id, 'random');
    });

    test('uses most recent post-dialysis before current', () {
      final result = weightGainSnapshotOnLocalDate(
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

      expect(result.postDialysis!.id, 'new-post');
      expect(result.gainKg, closeTo(1.5, 0.001));
    });

    test('carry-forward: current on prior day still pairs on later day', () {
      final result = weightGainSnapshotOnLocalDate(
        [
          reading(
            id: 'post',
            recordedAt: DateTime(2026, 7, 8, 14),
            valueKg: 70,
            dialysisTiming: dialysisTimingPostDialysis,
          ),
          reading(
            id: 'current',
            recordedAt: DateTime(2026, 7, 9, 9),
            valueKg: 71.5,
          ),
        ],
        day,
      );

      expect(result.status, WeightGainStatus.paired);
      expect(result.current!.id, 'current');
      expect(result.gainKg, closeTo(1.5, 0.001));
    });

    test('as-of date: ignores current logged after selected day', () {
      final result = weightGainSnapshotOnLocalDate(
        [
          reading(
            id: 'post',
            recordedAt: DateTime(2026, 7, 8, 14),
            valueKg: 70,
            dialysisTiming: dialysisTimingPostDialysis,
          ),
          reading(
            id: 'future-current',
            recordedAt: DateTime(2026, 7, 11, 9),
            valueKg: 73,
          ),
        ],
        day,
      );

      expect(result.status, WeightGainStatus.awaitingCurrent);
      expect(result.postDialysis!.id, 'post');
      expect(result.current, isNull);
    });

    test('awaiting current when only post-dialysis exists', () {
      final result = weightGainSnapshotOnLocalDate(
        [
          reading(
            id: 'post',
            recordedAt: DateTime(2026, 7, 8, 14),
            valueKg: 70,
            dialysisTiming: dialysisTimingPostDialysis,
          ),
        ],
        day,
      );

      expect(result.status, WeightGainStatus.awaitingCurrent);
      expect(result.postDialysis!.id, 'post');
      expect(result.current, isNull);
      expect(result.displayGain, isNull);
    });

    test('empty without post-dialysis baseline', () {
      final result = weightGainSnapshotOnLocalDate(
        [
          reading(
            id: 'current',
            recordedAt: DateTime(2026, 7, 10, 9),
            valueKg: 72,
          ),
        ],
        day,
      );

      expect(result.status, WeightGainStatus.empty);
      expect(result.asPaired, isNull);
    });

    test('ignores pre-dialysis without random context as current', () {
      final result = weightGainSnapshotOnLocalDate(
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

      expect(result.status, WeightGainStatus.awaitingCurrent);
    });

    test('formats negative gain without plus sign', () {
      final result = weightGainSnapshotOnLocalDate(
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

      expect(result.displayGain, '-1.0 kg');
    });

    test('weightGainFromDryWeightOnLocalDate returns paired only', () {
      final paired = weightGainFromDryWeightOnLocalDate(
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
            valueKg: 72,
          ),
        ],
        day,
      );
      expect(paired, isNotNull);
      expect(paired!.gainKg, closeTo(2.0, 0.001));

      final awaiting = weightGainFromDryWeightOnLocalDate(
        [
          reading(
            id: 'post',
            recordedAt: DateTime(2026, 7, 8, 14),
            valueKg: 70,
            dialysisTiming: dialysisTimingPostDialysis,
          ),
        ],
        day,
      );
      expect(awaiting, isNull);
    });

    test('trendLabel reflects gain direction', () {
      final increasing = weightGainSnapshotOnLocalDate(
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
            valueKg: 72,
          ),
        ],
        day,
      );
      expect(increasing.trendLabel, 'Increasing');
      expect(increasing.trendDirection, 1);

      final decreasing = weightGainSnapshotOnLocalDate(
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
      expect(decreasing.trendLabel, 'Decreasing');
      expect(decreasing.trendDirection, -1);
    });

    test('weightGainChartOnLocalDate builds dry baseline and cycle points', () {
      final chart = weightGainChartOnLocalDate(
        [
          reading(
            id: 'post',
            recordedAt: DateTime(2026, 7, 8, 14),
            valueKg: 70,
            dialysisTiming: dialysisTimingPostDialysis,
          ),
          reading(
            id: 'mid',
            recordedAt: DateTime(2026, 7, 9, 10),
            valueKg: 71.2,
          ),
          reading(
            id: 'current',
            recordedAt: DateTime(2026, 7, 10, 9),
            valueKg: 72.5,
          ),
        ],
        day,
      );

      expect(chart.hasSeries, isTrue);
      expect(chart.dryWeightKg, 70);
      expect(chart.weights, hasLength(3));
      expect(chart.weights.first.valueKg, 70);
      expect(chart.weights.last.valueKg, 72.5);
    });
  });
}
