import 'package:app/data/sync/remote_mappers.dart';
import 'package:app/domain/models/blood_pressure_context.dart';
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

  test('blood pressure context round-trips through remote json', () {
    final row = bloodPressureRowFromRemoteJson({
      'id': 'bp-1',
      'patient_id': 'patient-1',
      'recorded_at': '2026-07-08T10:00:00Z',
      'systolic': 130,
      'diastolic': 85,
      'arm': bpArmLeft,
      'posture': bpPostureSitting,
      'is_dialysis_day': true,
      'dialysis_phase': bpDialysisPhasePost,
      'created_at': '2026-07-08T10:00:00Z',
      'updated_at': '2026-07-08T10:00:00Z',
    });

    expect(row.arm, bpArmLeft);
    expect(row.posture, bpPostureSitting);
    expect(row.isDialysisDay, isTrue);
    expect(row.dialysisPhase, bpDialysisPhasePost);

    final json = bloodPressureRowToRemoteJson(row);
    expect(json['arm'], bpArmLeft);
    expect(json['posture'], bpPostureSitting);
    expect(json['is_dialysis_day'], isTrue);
    expect(json['dialysis_phase'], bpDialysisPhasePost);
  });

  test('legacy blood pressure json without context maps to nulls', () {
    final row = bloodPressureRowFromRemoteJson({
      'id': 'bp-1',
      'patient_id': 'patient-1',
      'recorded_at': '2026-07-08T10:00:00Z',
      'systolic': 130,
      'diastolic': 85,
      'created_at': '2026-07-08T10:00:00Z',
      'updated_at': '2026-07-08T10:00:00Z',
    });

    expect(row.arm, isNull);
    expect(row.isDialysisDay, isNull);
    expect(bloodPressureRowToRemoteJson(row)['dialysis_phase'], isNull);
  });

  test('recorded_by is pulled but never pushed (server-set)', () {
    final row = bloodGlucoseRowFromRemoteJson({
      'id': 'bg-1',
      'patient_id': 'patient-1',
      'recorded_at': '2026-07-08T10:00:00Z',
      'value_mg_dl': 110,
      'context': 'before_meal',
      'recorded_by': 'auth-2',
      'created_at': '2026-07-08T10:00:00Z',
      'updated_at': '2026-07-08T10:00:00Z',
    });
    expect(row.recordedBy, 'auth-2');
    expect(row.context, 'before_meal');

    final json = bloodGlucoseRowToRemoteJson(row);
    expect(json.containsKey('recorded_by'), isFalse);
    expect(json['context'], 'before_meal');
  });

  test('patient blood_group maps both ways', () {
    final row = patientRowFromRemoteJson({
      'id': 'patient-1',
      'auth_user_id': 'auth-1',
      'blood_group': 'O-',
      'created_at': '2026-07-08T10:00:00Z',
      'updated_at': '2026-07-08T10:00:00Z',
    });
    expect(row.bloodGroup, 'O-');
    expect(patientRowToRemoteJson(row)['blood_group'], 'O-');
  });
}
