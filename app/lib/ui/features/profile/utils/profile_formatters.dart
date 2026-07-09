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
