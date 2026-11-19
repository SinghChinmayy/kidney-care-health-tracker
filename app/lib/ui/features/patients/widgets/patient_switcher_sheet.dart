import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/patients/view_models/patients_view_model.dart';
import 'package:app/ui/features/patients/views/manage_patients_view.dart';
import 'package:app/ui/features/patients/widgets/patient_role_badge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Bottom sheet listing accessible patients; tapping one makes it active.
Future<void> showPatientSwitcherSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return ChangeNotifierProvider.value(
        value: context.read<PatientsViewModel>(),
        child: _PatientSwitcherSheet(parentContext: context),
      );
    },
  );
}

class _PatientSwitcherSheet extends StatelessWidget {
  const _PatientSwitcherSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PatientsViewModel>();
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingSm,
          AppTheme.spacingSm,
          AppTheme.spacingSm,
          AppTheme.spacingXs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Switch patient',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in viewModel.patients)
                    ListTile(
                      key: ValueKey('switch-${entry.patient.id}'),
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        entry.patient.id == viewModel.activePatientId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: AppTheme.ink,
                      ),
                      title: Text(
                        entry.isSelf
                            ? '${entry.displayName} (you)'
                            : entry.displayName,
                      ),
                      trailing: PatientRoleBadge(role: entry.role),
                      onTap: () async {
                        await viewModel.switchTo(entry.patient.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(parentContext).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManagePatientsView(),
                  ),
                );
              },
              style: AppTheme.secondaryButtonStyle(),
              icon: const Icon(Icons.group_outlined),
              label: const Text('Manage patients'),
            ),
          ],
        ),
      ),
    );
  }
}
