import 'package:app/domain/models/weight_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/vitals/models/weight_period.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_sheets.dart';
import 'package:app/ui/features/vitals/widgets/weight_edit_sheet.dart';
import 'package:app/ui/features/vitals/widgets/weight_period_selector.dart';
import 'package:app/ui/features/vitals/widgets/weight_recent_card.dart';
import 'package:app/ui/features/vitals/widgets/weight_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeightView extends StatefulWidget {
  const WeightView({super.key});

  @override
  State<WeightView> createState() => _WeightViewState();
}

class _WeightViewState extends State<WeightView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WeightViewModel>().refresh();
    });
  }

  Future<void> _logWeight() {
    final viewModel = context.read<WeightViewModel>();
    return showWeightLogSheet(
      context,
      onSaved: viewModel.refresh,
    );
  }

  Future<void> _editReading(WeightReading reading) {
    final viewModel = context.read<WeightViewModel>();
    return showWeightEditSheet(
      context,
      reading: reading,
      viewModel: viewModel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeightViewModel>();
    final theme = Theme.of(context);
    final heroKg = viewModel.heroWeightKg;
    final change = viewModel.periodChangeKg;
    final avg = viewModel.periodAverageKg;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppScreenAppBar(
        title: 'Weight',
        actions: [
          IconButton(
            tooltip: 'Log weight',
            onPressed: _logWeight,
            icon: const Icon(Icons.add),
          ),
        ],
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
                  WeightPeriodSelector(
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
                    heroKg == null ? '—' : heroKg.toStringAsFixed(1),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                      height: 1.05,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'kg',
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
                              : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                          label: 'Change',
                          valueColor: change == null
                              ? null
                              : change > 0.05
                                  ? AppTheme.error
                                  : AppTheme.ink,
                        ),
                      ),
                      Expanded(
                        child: _SummaryStat(
                          value: avg == null ? '—' : avg.toStringAsFixed(1),
                          label: 'Avg kg',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  WeightTrendChart(days: viewModel.chartDays),
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
                  AppTheme.spacingLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Recent',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    if (viewModel.readings.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingMd,
                        ),
                        child: Text(
                          'No weight readings yet. Tap + to log one.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.muted,
                          ),
                        ),
                      )
                    else
                      for (final reading in viewModel.readings) ...[
                        WeightRecentCard(
                          reading: reading,
                          deltaKg: viewModel.changeVsPrevious(reading),
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
