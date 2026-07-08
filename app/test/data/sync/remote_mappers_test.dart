import 'package:app/data/sync/remote_mappers.dart';
import 'package:app/domain/models/weight_reading_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weightRowFromRemoteJson defaults missing dialysis_timing', () {
    final row = weightRowFromRemoteJson({
      'id': 'weight-1',
      'patient_id': 'patient-1',
      'recorded_at': '2026-07-08T10:00:00Z',
      'value_kg': 72.5,
      'source': 'manual',
      'created_at': '2026-07-08T10:00:00Z',
      'updated_at': '2026-07-08T10:00:00Z',
    });

    expect(row.dialysisTiming, dialysisTimingNonDialysis);
    expect(row.weightContext, isNull);
  });

  test('weightRowToRemoteJson includes dialysis fields', () {
    final json = weightRowToRemoteJson(
      weightRowFromRemoteJson({
        'id': 'weight-1',
        'patient_id': 'patient-1',
        'recorded_at': '2026-07-08T10:00:00Z',
        'value_kg': 72.5,
        'dialysis_timing': dialysisTimingPreDialysis,
        'weight_context': 'morning',
        'source': 'manual',
        'created_at': '2026-07-08T10:00:00Z',
        'updated_at': '2026-07-08T10:00:00Z',
      }),
    );

    expect(json['dialysis_timing'], dialysisTimingPreDialysis);
    expect(json['weight_context'], 'morning');
  });
}
