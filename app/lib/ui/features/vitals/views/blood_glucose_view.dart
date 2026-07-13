import 'package:app/domain/models/blood_glucose_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_edit_sheet.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_period_selector.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_recent_card.dart';
import 'package:app/ui/features/vitals/widgets/blood_glucose_trend_chart.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_sheets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BloodGlucoseView extends StatefulWidget {
  const BloodGlucoseView({super.key});

  @override
  State<BloodGlucoseView> createState() => _BloodGlucoseViewState();
}

class _BloodGlucoseViewState extends State<BloodGlucoseView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BloodGlucoseViewModel>().refresh();
    });
  }

  Future<void> _logGlucose() {
    final viewModel = context.read<BloodGlucoseViewModel>();
    return showBloodGlucoseLogSheet(
      context,
      onSaved: viewModel.refresh,
    );
  }

  Future<void> _editReading(BloodGlucoseReading reading) {
    final viewModel = context.read<BloodGlucoseViewModel>();
    return showBloodGlucoseEditSheet(
      context,
      reading: reading,
      viewModel: viewModel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BloodGlucoseViewModel>();
    final theme = Theme.of(context);
    final hero = viewModel.heroValueMgDl;
    final change = viewModel.periodChangeMgDl;
    final avg = viewModel.periodAverageMgDl;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppScreenAppBar(title: 'Blood glucose'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logGlucose,
        tooltip: 'Log blood glucose',
        icon: const Icon(Icons.add),
        label: const Text(
          'Log',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingSm,
                AppTheme.spacingXs,
                AppTheme.spacingSm,
                AppTheme.spacingSm,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  BloodGlucosePeriodSelector(
                    selected: viewModel.selectedPeriod,
                    onSelected: viewModel.selectPeriod,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  if (viewModel.showsPeriodNavigator)
                    Row(
                      children: [
                        IconButton(
                          tooltip: viewModel.previousPeriodTooltip,
                          onPressed: viewModel.canSelectPreviousPeriod
                              ? viewModel.selectPreviousPeriod
                              : null,
                          icon: const Icon(Icons.chevron_left),
                          visualDensity: VisualDensity.compact,
                        ),
                        Expanded(
                          child: Text(
                            viewModel.selectedPeriodLabel,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.muted,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: viewModel.nextPeriodTooltip,
                          onPressed: viewModel.canSelectNextPeriod
                              ? viewModel.selectNextPeriod
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    )
                  else
                    Text(
                      viewModel.selectedPeriodLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.muted,
                      ),
                    ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    hero == null ? '—' : hero.toStringAsFixed(0),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                      height: 1.05,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'mg/dL',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryStat(
                          value: '${viewModel.periodReadingCount}',
                          label: 'Readings',
                        ),
                      ),
                      Expanded(
                        child: _SummaryStat(
                          value: change == null
                              ? '—'
                              : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}',
                          label: 'Change',
                          valueColor: change == null
                              ? null
                              : change > 5
                                  ? AppTheme.error
                                  : AppTheme.ink,
                        ),
                      ),
                      Expanded(
                        child: _SummaryStat(
                          value: avg == null ? '—' : avg.toStringAsFixed(0),
                          label: 'Avg mg/dL',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  BloodGlucoseTrendChart(days: viewModel.chartDays),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                color: AppTheme.cardSurface,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingSm,
                  AppTheme.spacingMd,
                  AppTheme.spacingSm,
                  96,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _logGlucose,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Log',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.logBloodGlucose,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    if (viewModel.readings.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingMd,
                        ),
                        child: Text(
                          'No glucose readings yet. Tap Log to add one.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.muted,
                          ),
                        ),
                      )
                    else
                      for (final reading in viewModel.readings) ...[
                        BloodGlucoseRecentCard(
                          reading: reading,
                          deltaMgDl: viewModel.changeVsPrevious(reading),
                          onTap: () => _editReading(reading),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.value,
    required this.label,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppTheme.ink,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }
}
