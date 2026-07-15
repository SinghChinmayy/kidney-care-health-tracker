import 'package:app/data/repositories/patient_medication_schedule_repository.dart';
import 'package:app/domain/models/patient_medication_schedule.dart';
import 'package:app/ui/features/profile/utils/profile_formatters.dart';
import 'package:flutter/material.dart';

class DialysisDaysChangeImpact {
  const DialysisDaysChangeImpact({
    required this.removedDays,
    required this.addedDays,
    required this.clearsAll,
  });

  final List<int> removedDays;
  final List<int> addedDays;
  final bool clearsAll;

  bool get needsWarning =>
      clearsAll || removedDays.isNotEmpty || addedDays.isNotEmpty;
}

DialysisDaysChangeImpact computeDialysisDaysChangeImpact({
  required List<int> oldDays,
  required List<int> newDays,
  required PatientMedicationSchedule? schedule,
}) {
  final oldSet = oldDays.toSet();
  final newSet = newDays.toSet();
  final removed = oldSet.difference(newSet).toList()..sort();
  final added = newSet.difference(oldSet).toList()..sort();

  final removedWithMeds = removed.where((day) {
    return (schedule?.byDay[day] ?? const []).isNotEmpty;
  }).toList();

  final clearsAll = newDays.isEmpty && (schedule?.hasAnyMeds ?? false);

  return DialysisDaysChangeImpact(
    removedDays: clearsAll ? removed : removedWithMeds,
    addedDays: added,
    clearsAll: clearsAll,
  );
}

/// Returns true if user confirms (or no warning needed). False = cancel.
Future<bool> confirmDialysisDaysScheduleChange(
  BuildContext context, {
  required DialysisDaysChangeImpact impact,
}) async {
  if (!impact.needsWarning) {
    return true;
  }

  final lines = <String>[];
  if (impact.clearsAll) {
    lines.add(
      'All dialysis-day medications will be cleared. '
      'You will need to re-add them after selecting days again.',
    );
  } else if (impact.removedDays.isNotEmpty) {
    final labels = impact.removedDays
        .map((d) => formatDialysisDaysOfWeekLabel([d]))
        .join(', ');
    lines.add(
      'Medications on $labels will be cleared. '
      'Re-add them for any days you keep or newly select.',
    );
  }
  if (impact.addedDays.isNotEmpty) {
    final labels = impact.addedDays
        .map((d) => formatDialysisDaysOfWeekLabel([d]))
        .join(', ');
    lines.add(
      '$labels will start empty. Daily or other-day meds are not copied — '
      'add medications for these days manually.',
    );
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Update dialysis days?'),
        content: Text(lines.join('\n\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

Future<bool> confirmClearScheduleForDialysisTypeNone(
  BuildContext context, {
  required PatientMedicationSchedule? schedule,
}) async {
  if (schedule == null || !schedule.hasAnyMeds) {
    return true;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Turn off dialysis?'),
        content: const Text(
          'All dialysis-day medications will be cleared. '
          'You will need to re-add them if you turn dialysis back on.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

Future<void> applyScheduleAfterDialysisDaysChange(
  PatientMedicationScheduleRepository repository, {
  required List<int> newDays,
}) {
  return repository.applyDialysisDaysChange(newDays: newDays);
}
