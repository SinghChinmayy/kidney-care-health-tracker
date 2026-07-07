import 'dart:async';

import 'package:app/data/sync/sync_engine.dart';

/// Debounced sync triggers — repositories call [onDriftWrite] after local writes.
class SyncCoordinator {
  SyncCoordinator({
    required SyncEngine engine,
    Duration debounce = const Duration(seconds: 2),
  })  : _engine = engine,
        _debounceDuration = debounce;

  final SyncEngine _engine;
  final Duration _debounceDuration;

  Timer? _debounceTimer;
  bool _running = false;
  bool _pendingRun = false;

  void onDriftWrite() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      unawaited(run());
    });
  }

  void onAppStartup() {
    unawaited(run());
  }

  void onAppResumed() {
    unawaited(run());
  }

  void onConnectivityRestored() {
    unawaited(run());
  }

  Future<void> run() async {
    if (_running) {
      _pendingRun = true;
      return;
    }
    _running = true;
    try {
      await _engine.run();
    } finally {
      _running = false;
      if (_pendingRun) {
        _pendingRun = false;
        unawaited(run());
      }
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
