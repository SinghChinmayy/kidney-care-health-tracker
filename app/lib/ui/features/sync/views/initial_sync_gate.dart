import 'dart:async';

import 'package:app/data/local/app_database.dart';
import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/services/connectivity_service.dart';
import 'package:app/data/sync/sync_coordinator.dart';
import 'package:app/theme/app_theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

enum _InitialSyncPhase {
  checking,
  blockedOffline,
  syncing,
  syncFailed,
  ready,
}

/// Blocks the app until the signed-in user has local health data synced at least once.
class InitialSyncGate extends StatefulWidget {
  const InitialSyncGate({super.key, required this.child});

  final Widget child;

  @override
  State<InitialSyncGate> createState() => _InitialSyncGateState();
}

class _InitialSyncGateState extends State<InitialSyncGate> {
  _InitialSyncPhase _phase = _InitialSyncPhase.checking;
  String? _errorMessage;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_evaluate());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _connectivitySubscription ??=
          Connectivity().onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (_) {},
      );
    } on MissingPluginException {
      _wasOffline = true;
    }
    unawaited(_initializeConnectivityState());
  }

  Future<void> _initializeConnectivityState() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (!mounted) {
        return;
      }
      _wasOffline = !_hasConnectivity(results);
    } on MissingPluginException {
      _wasOffline = true;
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = _hasConnectivity(results);
    if (isOnline && _wasOffline && _phase == _InitialSyncPhase.blockedOffline) {
      unawaited(_evaluate());
    }
    _wasOffline = !isOnline;
  }

  bool _hasConnectivity(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> _evaluate() async {
    if (!mounted) {
      return;
    }

    final auth = context.read<AuthRepository>();
    final db = context.read<AppDatabase>();
    final connectivity = context.read<ConnectivityService>();
    final coordinator = context.read<SyncCoordinator>();
    final authUserId = auth.currentSession?.user.id;
    if (authUserId == null) {
      return;
    }

    setState(() {
      _phase = _InitialSyncPhase.checking;
      _errorMessage = null;
    });

    if (await db.hasLocalDataForAuthUser(authUserId)) {
      if (!mounted) {
        return;
      }
      setState(() => _phase = _InitialSyncPhase.ready);
      return;
    }

    if (!await connectivity.isOnline()) {
      if (!mounted) {
        return;
      }
      setState(() => _phase = _InitialSyncPhase.blockedOffline);
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _phase = _InitialSyncPhase.syncing);

    try {
      await coordinator.run();
      if (!mounted) {
        return;
      }

      if (await db.hasLocalDataForAuthUser(authUserId)) {
        setState(() => _phase = _InitialSyncPhase.ready);
        return;
      }

      setState(() {
        _phase = _InitialSyncPhase.syncFailed;
        _errorMessage =
            'Could not sync your health data. Please try again when online.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _phase = _InitialSyncPhase.syncFailed;
        _errorMessage =
            'Sync failed. Check your connection and try again.';
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _InitialSyncPhase.ready:
        return widget.child;
      case _InitialSyncPhase.blockedOffline:
        return _GateScaffold(
          icon: Icons.wifi_off_outlined,
          title: 'You\'re offline',
          message:
              'Connect to the internet to sync your health data before using the app.',
          actionLabel: 'Try again',
          onAction: _evaluate,
        );
      case _InitialSyncPhase.syncFailed:
        return _GateScaffold(
          icon: Icons.cloud_off_outlined,
          title: 'Sync failed',
          message: _errorMessage ??
              'Could not sync your health data. Please try again.',
          actionLabel: 'Retry sync',
          onAction: _evaluate,
        );
      case _InitialSyncPhase.checking:
      case _InitialSyncPhase.syncing:
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      _phase == _InitialSyncPhase.syncing
                          ? 'Syncing your health data…'
                          : 'Checking local data…',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _GateScaffold extends StatelessWidget {
  const _GateScaffold({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingLg),
              Icon(icon, size: 48, color: AppTheme.ink),
              const SizedBox(height: AppTheme.spacingSm),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppTheme.spacingSm),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
