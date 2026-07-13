import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/journal/view_models/journal_view_model.dart';
import 'package:app/ui/features/journal/widgets/journal_section.dart';
import 'package:app/ui/features/medications/views/medications_view.dart';
import 'package:app/ui/features/profile/utils/profile_formatters.dart';
import 'package:app/ui/features/profile/view_models/profile_view_model.dart';
import 'package:app/ui/features/profile/widgets/profile_option_picker_sheet.dart';
import 'package:app/ui/features/vitals/views/weight_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _journalContentMaxWidth = 600;

class JournalView extends StatefulWidget {
  const JournalView({super.key});

  @override
  State<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<JournalView> {
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

  void _showSaveFeedback(
    bool saved,
    ProfileViewModel viewModel, {
    String successMessage = 'Updated',
  }) {
    if (!mounted) return;
    final message = saved
        ? successMessage
        : (viewModel.errorMessage ?? 'Could not update.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickDialysisType(ProfileViewModel viewModel) async {
    final selected = await showProfileOptionPickerSheet(
      context,
      title: 'Dialysis',
      selectedValue: viewModel.patient?.dialysisType ?? 'none',
      options: [
        for (final value in dialysisTypeOptions)
          ProfilePickerOption(
            value: value,
            label: formatDialysisTypeLabel(value),
          ),
      ],
    );
    if (!mounted || selected == null) return;
    final saved = await viewModel.updateDialysisType(selected);
    _showSaveFeedback(saved, viewModel);
  }

  Future<void> _pickDialysisDays(ProfileViewModel viewModel) async {
    final selected = await showProfileDialysisDaysPickerSheet(
      context,
      initialDays: viewModel.patient?.dialysisDaysOfWeek,
    );
    if (!mounted || selected == null) return;
    final saved = await viewModel.updateDialysisDaysOfWeek(selected);
    _showSaveFeedback(saved, viewModel);
  }

  Future<void> _pickCkdStage(ProfileViewModel viewModel) async {
    final selected = await showProfileOptionPickerSheet(
      context,
      title: 'CKD stage',
      selectedValue: viewModel.patient?.ckdStage,
      options: [
        for (final value in ckdStageOptions)
          ProfilePickerOption(
            value: value,
            label: formatCkdStageLabel(value),
          ),
      ],
    );
    if (!mounted || selected == null) return;
    final saved = await viewModel.updateCkdStage(selected);
    _showSaveFeedback(saved, viewModel);
  }

  Future<void> _pickDailyWaterGoal(ProfileViewModel viewModel) async {
    final selected = await showProfileWaterGoalPickerSheet(
      context,
      initialGoalMl: viewModel.preferences?.dailyWaterGoalMl,
    );
    if (!mounted || selected == null) return;
    final saved = await viewModel.updateDailyWaterGoalMl(selected);
    _showSaveFeedback(saved, viewModel, successMessage: 'Fluid limit updated');
  }

  void _openMedications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MedicationsView()),
    ).then((_) {
      if (mounted) context.read<JournalViewModel>().refresh();
    });
  }

  void _openWeight() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WeightView()),
    ).then((_) {
      if (mounted) context.read<JournalViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileViewModel>();
    final journal = context.watch<JournalViewModel>();
    final patient = profile.patient;
    final preferences = profile.preferences;
    final canEdit = patient != null && !profile.isSaving;
    final canEditPreferences = preferences != null && !profile.isSaving;

    return ColoredBox(
      color: AppTheme.bpBackground,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _journalContentMaxWidth),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingSm,
                  AppTheme.spacingSm,
                  AppTheme.spacingSm,
                  AppTheme.floatingNavClearance,
                ),
                children: [
                  Text(
                    'Journal',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'Dialysis prep & care plan in one place',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.muted,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  if (profile.isLoading && patient == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    JournalSection(
                      title: 'Dialysis prep',
                      children: [
                        JournalDetailRow(
                          icon: Icons.monitor_heart_outlined,
                          label: 'CKD stage',
                          value: formatCkdStageLabel(patient?.ckdStage),
                          onTap:
                              canEdit ? () => _pickCkdStage(profile) : null,
                        ),
                        const JournalDivider(),
                        JournalDetailRow(
                          icon: Icons.local_hospital_outlined,
                          label: 'Dialysis type',
                          value: formatDialysisTypeLabel(
                            patient?.dialysisType ?? 'none',
                          ),
                          onTap: canEdit
                              ? () => _pickDialysisType(profile)
                              : null,
                        ),
                        const JournalDivider(),
                        JournalDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Dialysis days',
                          value: formatDialysisDaysOfWeekLabel(
                            patient?.dialysisDaysOfWeek,
                          ),
                          onTap: canEdit
                              ? () => _pickDialysisDays(profile)
                              : null,
                        ),
                        const JournalDivider(),
                        JournalDetailRow(
                          icon: Icons.water_drop_outlined,
                          label: 'Daily fluid limit',
                          value: formatDailyWaterGoalLabel(
                            preferences?.dailyWaterGoalMl,
                          ),
                          onTap: canEditPreferences
                              ? () => _pickDailyWaterGoal(profile)
                              : null,
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    JournalSection(
                      title: 'Dry weight',
                      children: [
                        JournalDetailRow(
                          icon: Icons.monitor_weight_outlined,
                          label: 'Dry weight',
                          value: journal.dryWeightLabel,
                          subtitle: journal.dryWeightMetaLabel,
                          onTap: _openWeight,
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    JournalSection(
                      title: 'Medications',
                      trailing: TextButton(
                        onPressed: _openMedications,
                        child: const Text('Manage'),
                      ),
                      children: [
                        JournalDetailRow(
                          icon: Icons.medication_outlined,
                          label: 'Medication catalog',
                          value: journal.medicationCount == 0
                              ? 'Empty'
                              : '${journal.medicationCount} meds',
                          subtitle:
                              'Names, composition & notes for dialysis care',
                          onTap: _openMedications,
                          isLast: true,
                        ),
                      ],
                    ),
                    if (journal.medications.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingXs),
                      ...journal.medications.take(5).map((med) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingXs,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _openMedications,
                              borderRadius: BorderRadius.circular(
                                AppTheme.cardCornerRadius,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.spacingSm),
                                decoration: AppTheme.homeCardDecoration(
                                  elevated: false,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med.pharmaceuticalName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            med.composition,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.muted,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: AppTheme.muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (journal.medicationCount > 5)
                        TextButton(
                          onPressed: _openMedications,
                          child: Text(
                            'View all ${journal.medicationCount} medications',
                          ),
                        ),
                    ],
                    if (profile.isSaving) ...[
                      const SizedBox(height: AppTheme.spacingSm),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
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
