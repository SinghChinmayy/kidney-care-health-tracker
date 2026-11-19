import 'package:app/data/sync/sync_coordinator.dart';
import 'package:app/data/sync/sync_status.dart';
import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Slim banner shown only when sync needs the user's attention: the device
/// is offline, or the last run hit an error. Hidden otherwise.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key, required this.coordinator});

  final SyncCoordinator coordinator;

  static const offlineMessage =
      'Offline — changes are saved on this device and will sync automatically';
  static const errorMessage = "Couldn't sync — retrying automatically";

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: coordinator.status,
      builder: (context, status, _) {
        return switch (status.phase) {
          SyncPhase.offline => const _Banner(
              key: ValueKey('sync-banner-offline'),
              icon: Icons.cloud_off_outlined,
              message: offlineMessage,
              foreground: Color(0xFF57534E),
              background: Color(0xFFF5F5F4),
            ),
          SyncPhase.error => _Banner(
              key: const ValueKey('sync-banner-error'),
              icon: Icons.sync_problem_outlined,
              message: errorMessage,
              foreground: const Color(0xFFB45309),
              background: const Color(0xFFFFF7ED),
              actionLabel: 'Retry',
              onAction: coordinator.run,
            ),
          SyncPhase.idle || SyncPhase.syncing => const SizedBox.shrink(),
        };
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.icon,
    required this.message,
    required this.foreground,
    required this.background,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final Color foreground;
  final Color background;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      child: SafeArea(
        bottom: false,
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: 8,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: foreground,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(actionLabel!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
