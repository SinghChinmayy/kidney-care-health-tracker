import 'package:app/domain/models/patient_role.dart';
import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PatientRoleBadge extends StatelessWidget {
  const PatientRoleBadge({super.key, required this.role});

  final PatientRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Text(
        role.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
