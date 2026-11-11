import 'package:app/domain/models/accessible_patient.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/patients/view_models/patients_view_model.dart';
import 'package:app/ui/features/patients/views/add_patient_view.dart';
import 'package:app/ui/features/patients/widgets/patient_role_badge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Every patient the user can access, with the active one marked.
class ManagePatientsView extends StatelessWidget {
  const ManagePatientsView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PatientsViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Patients')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AddPatientView()),
        ),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add patient'),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: viewModel.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingSm,
                  AppTheme.spacingXs,
                  AppTheme.spacingSm,
                  AppTheme.floatingNavClearance,
                ),
                children: [
                  Text(
                    'Tap a patient to view and log their data. Patients '
                    'shared with you appear here after the next sync.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  for (final entry in viewModel.patients)
                    _PatientTile(
                      entry: entry,
                      isActive: entry.patient.id == viewModel.activePatientId,
                      onTap: () => viewModel.switchTo(entry.patient.id),
                    ),
                ],
              ),
            ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({
    required this.entry,
    required this.isActive,
    required this.onTap,
  });

  final AccessiblePatient entry;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingXs),
      elevation: 0,
      color: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius * 2),
        side: BorderSide(
          color: isActive ? AppTheme.ink : AppTheme.cardBorder,
        ),
      ),
      child: ListTile(
        key: ValueKey('patient-${entry.patient.id}'),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.surfaceMuted,
          foregroundColor: AppTheme.ink,
          child: Text(
            entry.displayName.characters.first.toUpperCase(),
          ),
        ),
        title: Text(entry.displayName),
        subtitle: Text(
          [
            if (entry.isSelf) 'You',
            if (isActive) 'Viewing now',
          ].join(' · '),
        ),
        trailing: PatientRoleBadge(role: entry.role),
      ),
    );
  }
}
