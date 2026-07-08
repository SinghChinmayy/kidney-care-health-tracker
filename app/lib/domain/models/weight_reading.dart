import 'package:app/domain/models/weight_reading_options.dart';

class WeightReading {
  const WeightReading({
    required this.id,
    required this.recordedAt,
    required this.valueKg,
    this.patientId,
    this.dialysisTiming = dialysisTimingNonDialysis,
    this.weightContext,
    this.source = 'manual',
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? patientId;
  final DateTime recordedAt;
  final double valueKg;
  final String dialysisTiming;
  final String? weightContext;
  final String source;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  String get displayValue => '${valueKg.toStringAsFixed(1)} kg';

  /// Human-readable label for [dialysisTiming].
  ///
  /// Future fluid-removal guidance can query latest [dialysisTimingPreDialysis]
  /// vs previous [dialysisTimingPostDialysis] — see planning for deferred work.
  String get displayTimingLabel => switch (dialysisTiming) {
        dialysisTimingPreDialysis => 'Pre-dialysis',
        dialysisTimingPostDialysis => 'Post-dialysis',
        _ => 'Non-dialysis day',
      };
}
