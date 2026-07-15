import 'package:app/domain/models/medication.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/journal/view_models/journal_view_model.dart';
import 'package:app/ui/features/journal/widgets/journal_section.dart';
import 'package:app/ui/features/journal/widgets/medication_day_sheets.dart';
import 'package:app/ui/features/medications/views/medications_view.dart';
import 'package:app/ui/features/profile/view_models/profile_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _journalContentMaxWidth = 600;

class JournalMedicinesView extends StatefulWidget {
  const JournalMedicinesView({super.key});

  @override
  State<JournalMedicinesView> createState() => _JournalMedicinesViewState();
}

class _JournalMedicinesViewState extends State<JournalMedicinesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileViewModel>().refresh();
      context.read<JournalViewModel>().refresh();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<ProfileViewModel>().refresh(),
      context.read<JournalViewModel>().refresh(),
    ]);
  }

  void _openMedicationsCatalog() {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(builder: (_) => const MedicationsView()),
    )
        .then((_) {
      if (mounted) context.read<JournalViewModel>().refresh();
    });
  }

  void _jumpToJournalDialysisDays() {
    Navigator.of(context).pop();
  }

  Future<void> _addMedForDay(int isoWeekday) async {
    final journal = context.read<JournalViewModel>();
    final existing = journal.schedule?.medIdsForDay(isoWeekday).toSet() ?? {};
    final picked = await showMedicationPickerSheet(
      context,
      medications: journal.medications,
      title: 'Add medicine · ${weekdayFullLabel(isoWeekday)}',
      excludeIds: existing,
    );
    if (!mounted || picked == null) return;

    final added = await journal.addMedToDay(
      isoWeekday: isoWeekday,
      medicationId: picked.id,
    );
    if (!mounted) return;
    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Already on ${weekdayFullLabel(isoWeekday)}',
          ),
        ),
      );
    }
  }

  Future<void> _onDayMedTap({
    required int isoWeekday,
    required Medication medication,
  }) async {
    final journal = context.read<JournalViewModel>();
    final action = await showDayMedActionsSheet(
      context,
      medicationName: medication.pharmaceuticalName,
    );
    if (!mounted || action == null) return;

    if (action == 'remove') {
      await journal.removeMedFromDay(
        isoWeekday: isoWeekday,
        medicationId: medication.id,
      );
      return;
    }

    if (action == 'replace') {
      final existing =
          journal.schedule?.medIdsForDay(isoWeekday).toSet() ?? {};
      final picked = await showMedicationPickerSheet(
        context,
        medications: journal.medications,
        title: 'Replace · ${medication.pharmaceuticalName}',
        excludeIds: existing.difference({medication.id}),
      );
      if (!mounted || picked == null) return;
      final ok = await journal.replaceMedOnDay(
        isoWeekday: isoWeekday,
        oldMedicationId: medication.id,
        newMedicationId: picked.id,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Already on ${weekdayFullLabel(isoWeekday)}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileViewModel>();
    final journal = context.watch<JournalViewModel>();
    final dialysisDays = [...(profile.patient?.dialysisDaysOfWeek ?? [])]
      ..sort();
    final hasDialysisDays = dialysisDays.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bpBackground,
      appBar: const AppScreenAppBar(title: 'Medicines'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: _journalContentMaxWidth),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingSm,
                  AppTheme.spacingSm,
                  AppTheme.spacingSm,
                  AppTheme.floatingNavClearance,
                ),
                children: [
                  if (profile.isLoading && profile.patient == null)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _DialysisDaysHintBanner(
                      onTap: _jumpToJournalDialysisDays,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    if (!hasDialysisDays)
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingSm),
                        decoration: AppTheme.homeCardDecoration(),
                        child: Text(
                          'Select dialysis days in Dialysis prep first '
                          'before assigning session medications.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppTheme.muted,
                              ),
                        ),
                      )
                    else ...[
                      for (var i = 0; i < dialysisDays.length; i++) ...[
                        _DialysisDayMedSection(
                          isoWeekday: dialysisDays[i],
                          ordinalLabel: dialysisDayOrdinalLabel(i),
                          meds: journal.medsForDaySorted(dialysisDays[i]),
                          onAdd: () => _addMedForDay(dialysisDays[i]),
                          onMedTap: (med) => _onDayMedTap(
                            isoWeekday: dialysisDays[i],
                            medication: med,
                          ),
                        ),
                        if (i < dialysisDays.length - 1)
                          const SizedBox(height: AppTheme.spacingMd),
                      ],
                    ],
                    const SizedBox(height: AppTheme.spacingMd),
                    JournalSection(
                      title: 'All medicines',
                      children: [
                        JournalDetailRow(
                          icon: Icons.medication_outlined,
                          label: 'View all medicines',
                          value: journal.medicationCount == 0
                              ? 'None yet'
                              : '${journal.medicationCount}',
                          onTap: _openMedicationsCatalog,
                          isLast: true,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialysisDaysHintBanner extends StatelessWidget {
  const _DialysisDaysHintBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardCornerRadius),
        child: Ink(
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
                Icons.calendar_today_outlined,
                color: AppTheme.logWeight.withValues(alpha: 1),
                size: 22,
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Expanded(
                child: Text(
                  'To change the days medicines are given, update '
                  'dialysis days in Journal.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Icon(
                Icons.chevron_right,
                size: 22,
                color: AppTheme.muted.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialysisDayMedSection extends StatelessWidget {
  const _DialysisDayMedSection({
    required this.isoWeekday,
    required this.ordinalLabel,
    required this.meds,
    required this.onAdd,
    required this.onMedTap,
  });

  final int isoWeekday;
  final String ordinalLabel;
  final List<Medication> meds;
  final VoidCallback onAdd;
  final void Function(Medication medication) onMedTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          weekdayFullLabel(isoWeekday),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          ordinalLabel,
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.muted),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                if (meds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    child: Text(
                      'No medications for this day',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < meds.length; i++) ...[
                    if (i > 0) const JournalDivider(),
                    ListTile(
                      title: Text(meds[i].pharmaceuticalName),
                      subtitle: Text(
                        meds[i].composition,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.more_horiz),
                      onTap: () => onMedTap(meds[i]),
                    ),
                  ],
                const JournalDivider(),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add medicine'),
                  onTap: onAdd,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
