/// Observable state of the foreground sync loop (see [SyncCoordinator]).
enum SyncPhase {
  /// Last run finished cleanly (or nothing has run yet).
  idle,

  /// A run is in progress.
  syncing,

  /// The connectivity probe failed; local writes stay queued.
  offline,

  /// The last run reached the server but at least one table failed.
  error,
}

class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.lastSuccessAt,
    this.failedTables = const [],
  });

  static const initial = SyncStatus();

  final SyncPhase phase;

  /// Wall-clock time of the last fully successful run.
  final DateTime? lastSuccessAt;

  /// Table keys whose push/pull failed in the last run.
  final List<String> failedTables;

  bool get needsAttention =>
      phase == SyncPhase.offline || phase == SyncPhase.error;

  SyncStatus copyWith({
    SyncPhase? phase,
    DateTime? lastSuccessAt,
    List<String>? failedTables,
  }) {
    return SyncStatus(
      phase: phase ?? this.phase,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      failedTables: failedTables ?? this.failedTables,
    );
  }
}

/// Outcome of one [SyncEngine.run].
class SyncRunResult {
  const SyncRunResult({this.failedTables = const []});

  final List<String> failedTables;

  bool get isSuccess => failedTables.isEmpty;
}
