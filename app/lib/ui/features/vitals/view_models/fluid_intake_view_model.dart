import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class FluidIntakeViewModel extends ChangeNotifier {
  FluidIntakeViewModel({required VitalsRepository vitalsRepository})
      : _vitalsRepository = vitalsRepository {
    refresh();
  }

  final VitalsRepository _vitalsRepository;
  List<FluidIntakeLog> _logs = [];

  List<FluidIntakeLog> get logs => _logs;

  double totalMlOnLocalDate(DateTime localDate) {
    final day = DateTime(localDate.year, localDate.month, localDate.day);
    var total = 0.0;
    for (final log in _logs) {
      final local = log.recordedAt.toLocal();
      final logDay = DateTime(local.year, local.month, local.day);
      if (logDay == day) {
        total += log.fluidMl;
      }
    }
    return total;
  }

  Future<void> refresh() async {
    _logs = await _vitalsRepository.getFluidIntakeLogs();
    notifyListeners();
  }

  Future<void> addLog({
    required double fluidMl,
    String? notes,
    DateTime? recordedAt,
  }) async {
    final log = FluidIntakeLog(
      id: const Uuid().v4(),
      recordedAt: (recordedAt ?? DateTime.now()).toUtc(),
      fluidMl: fluidMl,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    await _vitalsRepository.addFluidIntakeLog(log);
    await refresh();
  }
}
