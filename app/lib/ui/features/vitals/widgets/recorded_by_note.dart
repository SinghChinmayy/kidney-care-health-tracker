import 'package:app/data/repositories/sharing_repository.dart';
import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Logged by …" attribution line shown on reading detail/edit sheets.
class RecordedByNote extends StatelessWidget {
  const RecordedByNote({
    super.key,
    required this.recordedBy,
    required this.currentUserId,
    this.memberName,
    this.patientId,
  });

  /// auth user id stored on the row (server-set `recorded_by`).
  final String? recordedBy;
  final String? currentUserId;

  /// Display name for [recordedBy] when it is another member, if known.
  final String? memberName;

  /// When set (and [memberName] is not), another member's @username is
  /// looked up via [SharingRepository] (best effort; online only).
  final String? patientId;

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
    final author = recordedBy;
    final sharing = context.read<SharingRepository?>();
    if (author != null &&
        author != currentUserId &&
        memberName == null &&
        patientId != null &&
        sharing != null) {
      return FutureBuilder<String?>(
        future: sharing.memberHandle(patientId!, author),
        builder: (context, snapshot) => _line(
          context,
          labelFor(
            recordedBy: author,
            currentUserId: currentUserId,
            memberName: snapshot.data,
          ),
        ),
      );
    }
    return _line(
      context,
      labelFor(
        recordedBy: recordedBy,
        currentUserId: currentUserId,
        memberName: memberName,
      ),
    );
  }

  Widget _line(BuildContext context, String? label) {
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
