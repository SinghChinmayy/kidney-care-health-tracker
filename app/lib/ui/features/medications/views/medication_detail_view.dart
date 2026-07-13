import 'package:app/domain/models/medication.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:flutter/material.dart';

class MedicationDetailView extends StatelessWidget {
  const MedicationDetailView({super.key, required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.bpBackground,
      appBar: AppScreenAppBar(title: medication.pharmaceuticalName),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingSm,
          AppTheme.spacingXs,
          AppTheme.spacingSm,
          AppTheme.spacingXl,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: AppTheme.homeCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.pharmaceuticalName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _Section(
                  label: 'Composition',
                  body: medication.composition,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _Section(
                  label: 'About',
                  body: medication.about,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
      ],
    );
  }
}
