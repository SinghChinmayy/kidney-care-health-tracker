import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// "Logged by …" attribution line shown on reading detail/edit sheets.
class RecordedByNote extends StatelessWidget {
  const RecordedByNote({
    super.key,
    required this.recordedBy,
    required this.currentUserId,
    this.memberName,
  });

  /// auth user id stored on the row (server-set `recorded_by`).
  final String? recordedBy;
  final String? currentUserId;

  /// Display name for [recordedBy] when it is another member, if known.
  final String? memberName;

  static String? labelFor({
    required String? recordedBy,
    required String? currentUserId,
    String? memberName,
  }) {
    if (recordedBy == null) {
      return null;
    }
    if (recordedBy == currentUserId) {
      return 'Logged by you';
    }
    return 'Logged by ${memberName ?? 'another member'}';
  }

  @override
  Widget build(BuildContext context) {
    final label = labelFor(
      recordedBy: recordedBy,
      currentUserId: currentUserId,
      memberName: memberName,
    );
    if (label == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 14, color: AppTheme.muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.muted,
                ),
          ),
        ],
      ),
    );
  }
}
