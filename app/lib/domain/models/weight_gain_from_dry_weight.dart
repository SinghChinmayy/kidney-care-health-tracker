import 'package:app/domain/models/weight_reading.dart';
import 'package:app/domain/models/weight_reading_options.dart';

/// Interdialytic weight change from the last post-dialysis (dry) weight
/// to a later non-dialysis or random check reading.
class WeightGainFromDryWeight {
  const WeightGainFromDryWeight({
    required this.postDialysis,
    required this.current,
  });

  final WeightReading postDialysis;
  final WeightReading current;

  /// Positive when current weight is above the last post-dialysis weight.
  double get gainKg => current.valueKg - postDialysis.valueKg;

  String get displayGain {
    final signed = gainKg >= 0 ? '+' : '';
    return '$signed${gainKg.toStringAsFixed(1)} kg';
  }
}

enum WeightGainStatus {
  /// No post-dialysis baseline on or before the selected day.
  empty,

  /// Post-dialysis exists, but no eligible weight after it yet.
  awaitingCurrent,

  /// Post-dialysis + later eligible current weight.
  paired,
}

/// Snapshot of interdialytic weight state as of a local calendar day.
class WeightGainSnapshot {
  const WeightGainSnapshot.empty()
      : status = WeightGainStatus.empty,
        postDialysis = null,
        current = null;

  const WeightGainSnapshot.awaitingCurrent({
    required this.postDialysis,
  })  : status = WeightGainStatus.awaitingCurrent,
        current = null;

  const WeightGainSnapshot.paired({
    required this.postDialysis,
    required this.current,
  }) : status = WeightGainStatus.paired;

  final WeightGainStatus status;
  final WeightReading? postDialysis;
  final WeightReading? current;

  double? get gainKg {
    final post = postDialysis;
    final cur = current;
    if (post == null || cur == null) return null;
    return cur.valueKg - post.valueKg;
  }

  String? get displayGain {
    final gain = gainKg;
    if (gain == null) return null;
    final signed = gain >= 0 ? '+' : '';
    return '$signed${gain.toStringAsFixed(1)} kg';
  }

  WeightGainFromDryWeight? get asPaired {
    final post = postDialysis;
    final cur = current;
    if (status != WeightGainStatus.paired || post == null || cur == null) {
      return null;
    }
    return WeightGainFromDryWeight(postDialysis: post, current: cur);
  }

  /// Short trend label for the home weight-gain card.
  String get trendLabel {
    switch (status) {
      case WeightGainStatus.empty:
        return 'Log post-dialysis';
      case WeightGainStatus.awaitingCurrent:
        return 'Awaiting weight';
      case WeightGainStatus.paired:
        final gain = gainKg!;
        if (gain > 0.05) return 'Increasing';
        if (gain < -0.05) return 'Decreasing';
        return 'Stable';
    }
  }

  /// -1 decreasing, 0 stable/unknown, 1 increasing.
  int get trendDirection {
    switch (status) {
      case WeightGainStatus.empty:
      case WeightGainStatus.awaitingCurrent:
        return 0;
      case WeightGainStatus.paired:
        final gain = gainKg!;
        if (gain > 0.05) return 1;
        if (gain < -0.05) return -1;
        return 0;
    }
  }
}

/// Point on the interdialytic weight sparkline.
class WeightGainChartPoint {
  const WeightGainChartPoint({
    required this.recordedAt,
    required this.valueKg,
  });

  final DateTime recordedAt;
  final double valueKg;
}

/// Dual-series chart data for the home weight-gain card.
///
/// [dryWeightKg] is the post-dialysis baseline; [weights] are readings in the
/// current interdialytic window (including the post-dialysis start).
class WeightGainChartData {
  const WeightGainChartData({
    this.dryWeightKg,
    this.weights = const [],
  });

  final double? dryWeightKg;
  final List<WeightGainChartPoint> weights;

  bool get hasSeries => dryWeightKg != null && weights.isNotEmpty;
}

bool isWeightGainCurrentEntry(WeightReading reading) {
  return reading.dialysisTiming == dialysisTimingNonDialysis ||
      reading.weightContext == weightContextRandom;
}

DateTime _localDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Interdialytic weight state as of [localDate] (inclusive).
///
/// Uses the latest post-dialysis on/before [localDate], then the latest
/// eligible current entry after that post and on/before [localDate].
WeightGainSnapshot weightGainSnapshotOnLocalDate(
  List<WeightReading> readings,
  DateTime localDate,
) {
  final day = _localDateOnly(localDate);

  WeightReading? postDialysis;
  for (final reading in readings) {
    if (reading.dialysisTiming != dialysisTimingPostDialysis) {
      continue;
    }
    if (_localDateOnly(reading.recordedAt).isAfter(day)) {
      continue;
    }
    if (postDialysis == null ||
        reading.recordedAt.isAfter(postDialysis.recordedAt)) {
      postDialysis = reading;
    }
  }
  if (postDialysis == null) {
    return const WeightGainSnapshot.empty();
  }

  WeightReading? current;
  for (final reading in readings) {
    if (!isWeightGainCurrentEntry(reading)) {
      continue;
    }
    if (_localDateOnly(reading.recordedAt).isAfter(day)) {
      continue;
    }
    if (!reading.recordedAt.isAfter(postDialysis.recordedAt)) {
      continue;
    }
    if (current == null ||
        reading.recordedAt.isAfter(current.recordedAt)) {
      current = reading;
    }
  }
  if (current == null) {
    return WeightGainSnapshot.awaitingCurrent(postDialysis: postDialysis);
  }

  return WeightGainSnapshot.paired(
    postDialysis: postDialysis,
    current: current,
  );
}

/// Latest paired gain as of [localDate], or null when awaiting/empty.
WeightGainFromDryWeight? weightGainFromDryWeightOnLocalDate(
  List<WeightReading> readings,
  DateTime localDate,
) {
  return weightGainSnapshotOnLocalDate(readings, localDate).asPaired;
}

/// Chart series for the interdialytic window ending on [localDate].
WeightGainChartData weightGainChartOnLocalDate(
  List<WeightReading> readings,
  DateTime localDate,
) {
  final day = _localDateOnly(localDate);
  final snapshot = weightGainSnapshotOnLocalDate(readings, localDate);
  final post = snapshot.postDialysis;
  if (post == null) {
    return const WeightGainChartData();
  }

  final points = <WeightGainChartPoint>[
    WeightGainChartPoint(
      recordedAt: post.recordedAt,
      valueKg: post.valueKg,
    ),
  ];

  final sorted = [...readings]
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  for (final reading in sorted) {
    if (!reading.recordedAt.isAfter(post.recordedAt)) {
      continue;
    }
    if (_localDateOnly(reading.recordedAt).isAfter(day)) {
      continue;
    }
    points.add(
      WeightGainChartPoint(
        recordedAt: reading.recordedAt,
        valueKg: reading.valueKg,
      ),
    );
  }

  return WeightGainChartData(
    dryWeightKg: post.valueKg,
    weights: points,
  );
}
