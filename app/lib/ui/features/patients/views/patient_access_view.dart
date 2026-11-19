import 'package:app/data/repositories/sharing_repository.dart';
import 'package:app/domain/models/accessible_patient.dart';
import 'package:app/domain/models/patient_member.dart';
import 'package:app/domain/models/patient_role.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/patients/view_models/patient_access_view_model.dart';
import 'package:app/ui/features/patients/widgets/patient_role_badge.dart';
import 'package:app/ui/features/patients/widgets/username_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Who can see [patient]. Owners add people by username, change roles and
/// remove access; everyone else sees the list and can leave. Online-only.
class PatientAccessView extends StatelessWidget {
  const PatientAccessView({super.key, required this.patient});

  final AccessiblePatient patient;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PatientAccessViewModel(
        sharingRepository: context.read<SharingRepository>(),
        patient: patient,
      )..load(),
      child: const _PatientAccessBody(),
    );
  }
}

class _PatientAccessBody extends StatelessWidget {
  const _PatientAccessBody();

  void _toast(BuildContext context, String message) {
    showAccessMessage(context, message);
  }

  Future<void> _setUsername(
    BuildContext context,
    PatientAccessViewModel viewModel,
  ) async {
    final sharing = context.read<SharingRepository>();
    final saved = await showUsernameSheet(
      context,
      initial: viewModel.myUsername,
      save: (value) async {
        try {
          await sharing.setMyUsername(value);
          return null;
        } on SharingException catch (error) {
          return error.message;
        }
      },
    );
    if (saved != null) {
      await viewModel.load();
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    PatientAccessViewModel viewModel,
    PatientMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove access?'),
        content: Text(
          '${member.handle} will no longer be able to see or log '
          "${viewModel.patient.displayName}'s data.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final error = await viewModel.remove(member);
    if (context.mounted) {
      _toast(context, error ?? 'Access removed');
    }
  }

  Future<void> _confirmLeave(
    BuildContext context,
    PatientAccessViewModel viewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this patient?'),
        content: Text(
          "You will lose access to ${viewModel.patient.displayName}'s data "
          'on this device and everywhere else.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final error = await viewModel.leave();
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      _toast(context, error);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PatientAccessViewModel>();
    final theme = Theme.of(context);

    Widget body;
    if (viewModel.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (viewModel.loadError != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 32),
              const SizedBox(height: AppTheme.spacingXs),
              Text(viewModel.loadError!, textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.spacingSm),
              OutlinedButton(
                onPressed: viewModel.load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        children: [
          _UsernameCard(
            username: viewModel.myUsername,
            onEdit: () => _setUsername(context, viewModel),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'WHO HAS ACCESS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          for (final member in viewModel.members)
            _MemberTile(
              member: member,
              isMe: member.userId == viewModel.currentUserId,
              editable: viewModel.canEditMember(member),
              busy: viewModel.isBusy,
              onChangeRole: (role) async {
                final error = await viewModel.changeRole(member, role);
                if (context.mounted && error != null) {
                  _toast(context, error);
                }
              },
              onRemove: () => _confirmRemove(context, viewModel, member),
            ),
          if (viewModel.canManage) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _AddPersonForm(viewModel: viewModel),
          ] else ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'You have ${viewModel.patient.role.label.toLowerCase()} access. '
              'Only owners can add or remove people.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
              ),
            ),
          ],
          if (viewModel.canLeave) ...[
            const SizedBox(height: AppTheme.spacingMd),
            TextButton.icon(
              key: const ValueKey('leave-patient'),
              onPressed: viewModel.isBusy
                  ? null
                  : () => _confirmLeave(context, viewModel),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              icon: const Icon(Icons.logout),
              label: const Text('Leave this patient'),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Access · ${viewModel.patient.displayName}'),
      ),
      body: RefreshIndicator(onRefresh: viewModel.load, child: body),
    );
  }
}

/// Replaces any visible message so results show immediately.
void showAccessMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _UsernameCard extends StatelessWidget {
  const _UsernameCard({required this.username, required this.onEdit});

  final String? username;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.surfaceMuted,
      child: ListTile(
        leading: const Icon(Icons.alternate_email),
        title: Text(username == null ? 'No username yet' : '@$username'),
        subtitle: Text(
          username == null
              ? 'Pick one so others can share patients with you.'
              : 'Others share patients with you using this.',
        ),
        trailing: TextButton(
          onPressed: onEdit,
          child: Text(username == null ? 'Set' : 'Edit'),
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isMe,
    required this.editable,
    required this.busy,
    required this.onChangeRole,
    required this.onRemove,
  });

  final PatientMember member;
  final bool isMe;
  final bool editable;
  final bool busy;
  final ValueChanged<PatientRole> onChangeRole;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tags = [
      if (isMe) 'You',
      if (member.isPatient) 'Patient',
    ];
    return ListTile(
      key: ValueKey('member-${member.userId}'),
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: AppTheme.surfaceMuted,
        foregroundColor: AppTheme.ink,
        child: Icon(Icons.person_outline),
      ),
      title: Text(member.handle),
      subtitle: tags.isEmpty ? null : Text(tags.join(' · ')),
      trailing: editable
          ? PopupMenuButton<Object>(
              enabled: !busy,
              tooltip: 'Change access',
              onSelected: (value) {
                if (value is PatientRole) {
                  onChangeRole(value);
                } else {
                  onRemove();
                }
              },
              itemBuilder: (context) => [
                for (final role in PatientRole.values)
                  CheckedPopupMenuItem<Object>(
                    value: role,
                    checked: role == member.role,
                    child: Text(role.label),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem<Object>(
                  value: 'remove',
                  child: Text('Remove access'),
                ),
              ],
              child: PatientRoleBadge(role: member.role),
            )
          : PatientRoleBadge(role: member.role),
    );
  }
}

class _AddPersonForm extends StatefulWidget {
  const _AddPersonForm({required this.viewModel});

  final PatientAccessViewModel viewModel;

  @override
  State<_AddPersonForm> createState() => _AddPersonFormState();
}

class _AddPersonFormState extends State<_AddPersonForm> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  PatientRole _role = PatientRole.caregiver;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final error = await widget.viewModel.grant(_controller.text, _role);
    if (!mounted) {
      return;
    }
    if (error == null) {
      _controller.clear();
      showAccessMessage(context, 'Access granted');
    } else {
      showAccessMessage(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ADD PERSON',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          TextFormField(
            key: const ValueKey('grant-username'),
            controller: _controller,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Their username',
              prefixText: '@',
            ),
            validator: validateUsername,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SegmentedButton<PatientRole>(
            segments: [
              for (final role in PatientRole.values)
                ButtonSegment(value: role, label: Text(role.label)),
            ],
            selected: {_role},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _role = selection.first),
          ),
          const SizedBox(height: 4),
          Text(
            _role.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.muted,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ElevatedButton(
            key: const ValueKey('grant-submit'),
            onPressed: widget.viewModel.isBusy ? null : _submit,
            child: const Text('Give access'),
          ),
        ],
      ),
    );
  }
}
