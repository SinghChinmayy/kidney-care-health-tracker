import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/patients/view_models/patients_view_model.dart';
import 'package:app/ui/features/patients/widgets/patient_switcher_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shown above every tab while the user is viewing someone else's record,
/// so it's always clear whose data is being logged.
class ActivePatientBar extends StatelessWidget {
  const ActivePatientBar({super.key, this.removeTopInset = false});

  /// True when a banner above already consumed the status-bar inset.
  final bool removeTopInset;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PatientsViewModel>();
    final active = viewModel.activePatient;
    if (active == null || active.isSelf) {
      return const SizedBox.shrink();
    }

    final bar = Material(
      color: AppTheme.surfaceMuted,
      child: SafeArea(
        bottom: false,
        top: !removeTopInset,
        child: InkWell(
          onTap: () => showPatientSwitcherSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: 8,
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Viewing ${active.displayName} · ${active.role.label}',
                    key: const ValueKey('active-patient-bar'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text(
                  'Switch',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return bar;
  }
}
