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

bool isWeightGainCurrentEntry(WeightReading reading) {
  return reading.dialysisTiming == dialysisTimingNonDialysis ||
      reading.weightContext == weightContextRandom;
}

DateTime _localDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Latest eligible current entry on [localDate], paired with the most recent
/// post-dialysis reading recorded before it.
WeightGainFromDryWeight? weightGainFromDryWeightOnLocalDate(
  List<WeightReading> readings,
  DateTime localDate,
) {
  WeightReading? current;
  for (final reading in readings) {
    if (!isWeightGainCurrentEntry(reading)) {
      continue;
    }
    if (_localDateOnly(reading.recordedAt) != localDate) {
      continue;
    }
    if (current == null ||
        reading.recordedAt.isAfter(current.recordedAt)) {
      current = reading;
    }
  }
  if (current == null) {
    return null;
  }

  WeightReading? postDialysis;
  for (final reading in readings) {
    if (reading.dialysisTiming != dialysisTimingPostDialysis) {
      continue;
    }
    if (!reading.recordedAt.isBefore(current.recordedAt)) {
      continue;
    }
    if (postDialysis == null ||
        reading.recordedAt.isAfter(postDialysis.recordedAt)) {
      postDialysis = reading;
    }
  }
  if (postDialysis == null) {
    return null;
  }

  return WeightGainFromDryWeight(
    postDialysis: postDialysis,
    current: current,
  );
}
