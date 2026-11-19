import 'dart:async';

import 'package:app/data/sync/sync_engine.dart';
import 'package:app/data/sync/sync_status.dart';
import 'package:flutter/foundation.dart';

/// Debounced sync triggers — repositories call [onDriftWrite] after local writes.
///
/// Also owns the observable [status] (for the sync banner) and a periodic
/// foreground retry loop started/stopped by the lifecycle observer.
class SyncCoordinator {
  SyncCoordinator({
    required SyncEngine engine,
    Duration debounce = const Duration(seconds: 2),
    Duration retryInterval = const Duration(seconds: 45),
    Future<bool> Function()? isOnline,
    DateTime Function()? clock,
  })  : _engine = engine,
        _debounceDuration = debounce,
        _retryEvery = retryInterval,
        _onlineProbe = isOnline,
        _clock = clock ?? DateTime.now;

  final SyncEngine _engine;
  final Duration _debounceDuration;
  final Duration _retryEvery;
  final Future<bool> Function()? _onlineProbe;
  final DateTime Function() _clock;

  final ValueNotifier<SyncStatus> _status = ValueNotifier(SyncStatus.initial);

  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _running = false;
  bool _pendingRun = false;
  bool _disposed = false;

  ValueListenable<SyncStatus> get status => _status;

  bool get isPeriodicRetryActive => _retryTimer?.isActive ?? false;

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

  /// Starts the foreground loop: every [retryInterval] a run retries queued
  /// writes and pulls changes made by other members. Idempotent.
  void startPeriodicRetry() {
    if (_disposed || isPeriodicRetryActive) {
      return;
    }
    _retryTimer = Timer.periodic(_retryEvery, (_) {
      unawaited(run());
    });
  }

  void stopPeriodicRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Clears status after sign-out so the next account starts clean.
  void reset() {
    stopPeriodicRetry();
    _debounceTimer?.cancel();
    _setStatus(SyncStatus.initial);
  }

  Future<void> run() async {
    if (_disposed) {
      return;
    }
    if (_running) {
      _pendingRun = true;
      return;
    }
    _running = true;
    try {
      final probe = _onlineProbe;
      if (probe != null && !await probe()) {
        _setStatus(
          _status.value.copyWith(phase: SyncPhase.offline, failedTables: []),
        );
        return;
      }

      _setStatus(_status.value.copyWith(phase: SyncPhase.syncing));
      final result = await _engine.run();
      if (result.isSuccess) {
        _setStatus(
          SyncStatus(phase: SyncPhase.idle, lastSuccessAt: _clock()),
        );
      } else {
        _setStatus(
          _status.value.copyWith(
            phase: SyncPhase.error,
            failedTables: result.failedTables,
          ),
        );
      }
    } catch (error, stackTrace) {
      logSyncInfo('Sync run crashed: $error\n$stackTrace');
      _setStatus(_status.value.copyWith(phase: SyncPhase.error));
    } finally {
      _running = false;
      if (_pendingRun && !_disposed) {
        _pendingRun = false;
        unawaited(run());
      }
    }
  }

  void _setStatus(SyncStatus next) {
    if (!_disposed) {
      _status.value = next;
    }
  }

  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    stopPeriodicRetry();
    _status.dispose();
  }
}
