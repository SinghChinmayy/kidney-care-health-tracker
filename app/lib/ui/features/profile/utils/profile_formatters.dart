const ckdStageOptions = [
  'stage_1',
  'stage_2',
  'stage_3a',
  'stage_3b',
  'stage_4',
  'stage_5',
  'dialysis',
  'transplant',
];

const dialysisTypeOptions = [
  'none',
  'hemodialysis',
  'peritoneal',
];

const sexOptions = [
  'Female',
  'Male',
  'Other',
  'Prefer not to say',
];

String formatWeightUnitLabel(String? value) {
  return switch (value) {
    'kg' => 'kg',
    'lb' => 'lb',
    null || '' => 'kg',
    _ => value,
  };
}

String formatBloodGlucoseUnitLabel(String? value) {
  return switch (value) {
    'mg_dl' => 'mg/dL',
    'mmol_l' => 'mmol/L',
    null || '' => 'mg/dL',
    _ => value,
  };
}

String formatDailyWaterGoalLabel(int? value) {
  final ml = value ?? 1200;
  return '$ml ml';
}

String formatDialysisDaysOfWeekLabel(List<int>? days) {
  if (days == null) {
    return 'Not set';
  }
  if (days.isEmpty) {
    return 'None';
  }
  const labels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };
  final sorted = [...days]..sort();
  return sorted.map((day) => labels[day] ?? '$day').join(', ');
}

String formatCkdStageLabel(String? value) {
  if (value == null || value.isEmpty) {
    return 'Not set';
  }
  return switch (value) {
    'stage_1' => 'Stage 1',
    'stage_2' => 'Stage 2',
    'stage_3a' => 'Stage 3a',
    'stage_3b' => 'Stage 3b',
    'stage_4' => 'Stage 4',
    'stage_5' => 'Stage 5',
    'dialysis' => 'Dialysis',
    'transplant' => 'Transplant',
    _ => value,
  };
}

String formatDialysisTypeLabel(String value) {
  return switch (value) {
    'none' => 'None',
    'hemodialysis' => 'Hemodialysis',
    'peritoneal' => 'Peritoneal',
    _ => value,
  };
}

String formatSexLabel(String? value) {
  if (value == null || value.isEmpty) {
    return 'Not set';
  }
  return value;
}

String formatDateOfBirthLabel(DateTime? value) {
  if (value == null) {
    return 'Not set';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String formatHeightLabel(double? heightCm) {
  if (heightCm == null) {
    return 'Not set';
  }
  if (heightCm == heightCm.roundToDouble()) {
    return '${heightCm.toStringAsFixed(0)} cm';
  }
  return '${heightCm.toStringAsFixed(1)} cm';
}
