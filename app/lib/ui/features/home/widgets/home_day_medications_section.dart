import 'package:app/domain/models/medication.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/medications/views/medication_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dialysis-day banner + medicines for the selected calendar day.
class HomeDayMedicationsSection extends StatelessWidget {
  const HomeDayMedicationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    if (!viewModel.isSelectedDateDialysisDay) {
      return const SizedBox.shrink();
    }

    final meds = viewModel.medicationsForSelectedDate;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppTheme.logWeight.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppTheme.cardCornerRadius),
            border: Border.all(
              color: AppTheme.logWeight.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.water_drop_outlined,
                color: AppTheme.logWeight.withValues(alpha: 1),
                size: 22,
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Expanded(
                child: Text(
                  viewModel.dialysisDayBannerLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          viewModel.medicationsForSelectedDateTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Container(
          decoration: AppTheme.homeCardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: meds.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    child: Text(
                      'No medicines scheduled for this dialysis day. '
                      'Add them in Journal.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < meds.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: AppTheme.cardBorder,
                          ),
                        _HomeDayMedTile(
                          medication: meds[i],
                          onTap: () => _openDetail(context, meds[i]),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _openDetail(BuildContext context, Medication medication) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MedicationDetailView(medication: medication),
      ),
    );
  }
}

class _HomeDayMedTile extends StatelessWidget {
  const _HomeDayMedTile({
    required this.medication,
    required this.onTap,
  });

  final Medication medication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.medication_outlined,
          color: AppTheme.ink,
          size: 22,
        ),
      ),
      title: Text(
        medication.pharmaceuticalName,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        medication.composition,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.muted),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
      onTap: onTap,
    );
  }
}
