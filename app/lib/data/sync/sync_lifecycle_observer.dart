import 'dart:async';

import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/sync/sync_coordinator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wires lifecycle and auth-session sync triggers (planning/sync/v0/stage-1.md §5.2).
class SyncLifecycleObserver extends StatefulWidget {
  const SyncLifecycleObserver({super.key, required this.child});

  final Widget child;

  @override
  State<SyncLifecycleObserver> createState() => _SyncLifecycleObserverState();
}

class _SyncLifecycleObserverState extends State<SyncLifecycleObserver>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  SyncCoordinator? _coordinator;
  AuthRepository? _authRepository;
  bool _startupTriggered = false;
  bool _connectivityInitialized = false;
  bool _wasOffline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _coordinator ??= context.read<SyncCoordinator>();
    _authRepository ??= context.read<AuthRepository>();

    _authSubscription ??= _authRepository!.onAuthStateChange.listen((state) {
      if (state.session != null) {
        _startupTriggered = false;
        _triggerStartupSync();
      } else {
        _startupTriggered = false;
      }
    });

    try {
      _connectivitySubscription ??=
          Connectivity().onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (_) {},
      );
    } on MissingPluginException {
      _connectivityInitialized = true;
      _wasOffline = true;
    }

    if (_authRepository!.currentSession != null) {
      _triggerStartupSync();
    }

    unawaited(_initializeConnectivityState());
  }

  Future<void> _initializeConnectivityState() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (!mounted) {
        return;
      }
      _wasOffline = !_isOnline(results);
    } on MissingPluginException {
      _wasOffline = true;
    } finally {
      if (mounted) {
        _connectivityInitialized = true;
      }
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = _isOnline(results);
    if (_connectivityInitialized &&
        isOnline &&
        _wasOffline &&
        _authRepository?.currentSession != null) {
      _coordinator?.onConnectivityRestored();
    }
    if (_connectivityInitialized) {
      _wasOffline = !isOnline;
    }
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  void _triggerStartupSync() {
    if (_startupTriggered) {
      return;
    }
    _startupTriggered = true;
    _coordinator?.onAppStartup();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _coordinator?.onAppResumed();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _coordinator?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
