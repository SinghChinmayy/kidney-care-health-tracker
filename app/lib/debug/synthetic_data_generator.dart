import 'dart:math';

import 'package:app/data/repositories/vitals_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:app/domain/models/weight_reading.dart';
import 'package:app/domain/models/weight_reading_options.dart';
import 'package:uuid/uuid.dart';

class SyntheticDataGenerator {
  static Future<void> generate6MonthsData(VitalsRepository vitalsRepository) async {
    if (!kDebugMode) {
      return;
    }

    final patient = await vitalsRepository.getCurrentPatient();
    if (patient == null) return;

    final patientId = patient.id;
    final random = Random();
    final uuid = const Uuid();
    final now = DateTime.now();

    // Generate for the last 180 days
    double currentWeight = 72.0;

    for (int dayOffset = 180; dayOffset >= 0; dayOffset--) {
      final dayDate = now.subtract(Duration(days: dayOffset));

      // 1. Blood Pressure: 1 to 3 times per day
      final bpCount = random.nextInt(3) + 1;
      for (int i = 0; i < bpCount; i++) {
        // Distribute timings across the day
        final hour = 8 + (i * 5) + random.nextInt(3);
        final recordedAt = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          hour,
          random.nextInt(60),
        ).toUtc();

        final baseSys = 120 + sin(dayOffset * 0.1) * 8; // add a wave pattern
        final systolic = (baseSys + random.nextInt(15) - 7).round();
        final diastolic = (systolic - 40 + random.nextInt(10) - 5).round().clamp(60, 95);
        final heartRate = 60 + random.nextInt(30);

        final bp = BloodPressureReading(
          id: uuid.v4(),
          patientId: patientId,
          recordedAt: recordedAt,
          systolic: systolic,
          diastolic: diastolic,
          heartRateBpm: heartRate,
          notes: random.nextDouble() < 0.15 ? 'Feeling fine' : null,
        );
        await vitalsRepository.addBloodPressureReading(bp);
      }

      // 2. Blood Glucose: 1 to 3 times per day
      final glucoseCount = random.nextInt(3) + 1;
      final glucoseContexts = ['fasting', 'before_meal', 'after_meal', 'bedtime'];
      for (int i = 0; i < glucoseCount; i++) {
        final hour = 7 + (i * 6) + random.nextInt(2);
        final recordedAt = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          hour,
          random.nextInt(60),
        ).toUtc();

        final ctx = glucoseContexts[random.nextInt(glucoseContexts.length)];
        double val = 100.0;
        if (ctx == 'fasting') {
          val = 80.0 + random.nextInt(40);
        } else if (ctx == 'after_meal') {
          val = 130.0 + random.nextInt(70);
        } else {
          val = 95.0 + random.nextInt(50);
        }

        final bg = BloodGlucoseReading(
          id: uuid.v4(),
          patientId: patientId,
          recordedAt: recordedAt,
          valueMgDl: val,
          context: ctx,
          notes: random.nextDouble() < 0.1 ? 'Routine test' : null,
        );
        await vitalsRepository.addBloodGlucoseReading(bg);
      }

      // 3. Weight: Every 1 to 2 days
      if (dayOffset % 2 == 0 || random.nextDouble() < 0.4) {
        final hour = 6 + random.nextInt(3);
        final recordedAt = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          hour,
          random.nextInt(60),
        ).toUtc();

        // Slow random walk for weight
        currentWeight += (random.nextDouble() - 0.49) * 0.4;
        currentWeight = currentWeight.clamp(68.0, 76.0);

        final timing = random.nextDouble() < 0.3
            ? dialysisTimingPreDialysis
            : (random.nextDouble() < 0.5 ? dialysisTimingPostDialysis : dialysisTimingNonDialysis);

        final wt = WeightReading(
          id: uuid.v4(),
          patientId: patientId,
          recordedAt: recordedAt,
          valueKg: double.parse(currentWeight.toStringAsFixed(1)),
          dialysisTiming: timing,
          weightContext: timing != dialysisTimingNonDialysis ? 'clinic' : 'home',
        );
        await vitalsRepository.addWeightReading(wt);
      }

      // 4. Fluid Intake: 2 to 4 logs per day
      final fluidCount = random.nextInt(3) + 2;
      for (int i = 0; i < fluidCount; i++) {
        final hour = 9 + (i * 4) + random.nextInt(2);
        final recordedAt = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          hour,
          random.nextInt(60),
        ).toUtc();

        final ml = (150 + random.nextInt(350)).toDouble();

        final log = FluidIntakeLog(
          id: uuid.v4(),
          patientId: patientId,
          recordedAt: recordedAt,
          fluidMl: ml,
          notes: random.nextDouble() < 0.2 ? 'Water' : null,
        );
        await vitalsRepository.addFluidIntakeLog(log);
      }
    }
  }
}
