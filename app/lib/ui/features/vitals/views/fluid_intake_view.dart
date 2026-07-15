import 'package:app/domain/models/fluid_intake_log.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/vitals/view_models/fluid_intake_view_model.dart';
import 'package:app/ui/features/vitals/widgets/fluid_intake_edit_sheet.dart';
import 'package:app/ui/features/vitals/widgets/fluid_intake_period_selector.dart';
import 'package:app/ui/features/vitals/widgets/fluid_intake_recent_card.dart';
import 'package:app/ui/features/vitals/widgets/fluid_intake_summary_table.dart';
import 'package:app/ui/features/vitals/widgets/fluid_intake_trend_chart.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_sheets.dart';
import 'package:app/ui/features/vitals/widgets/week_grouped_history_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FluidIntakeView extends StatefulWidget {
  const FluidIntakeView({super.key});

  @override
  State<FluidIntakeView> createState() => _FluidIntakeViewState();
}

class _FluidIntakeViewState extends State<FluidIntakeView> {
  bool _showSummary = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FluidIntakeViewModel>().refresh();
    });
  }

  Future<void> _logFluid() {
    final viewModel = context.read<FluidIntakeViewModel>();
    return showFluidIntakeLogSheet(
      context,
      onSaved: viewModel.refresh,
    );
  }

  Future<void> _editLog(FluidIntakeLog log) {
    final viewModel = context.read<FluidIntakeViewModel>();
    return showFluidIntakeEditSheet(
      context,
      log: log,
      viewModel: viewModel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FluidIntakeViewModel>();
    final theme = Theme.of(context);
    final heroMl = viewModel.heroTotalMl;

    return Scaffold(
      backgroundColor: AppTheme.bpBackground,
      appBar: const AppScreenAppBar(title: 'Water intake'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logFluid,
        tooltip: 'Log water',
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
                  _SummaryGraphSelector(
                    isSummary: _showSummary,
                    onChanged: (val) => setState(() => _showSummary = val),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  _FluidSummaryStrip(
                    periodLabel: viewModel.selectedPeriodLabel,
                    value: heroMl?.toStringAsFixed(0),
                    unit: 'ml',
                    metaLabel: viewModel.heroMetaLabel,
                    showsPeriodNavigator: viewModel.showsPeriodNavigator,
                    canSelectPreviousPeriod: viewModel.canSelectPreviousPeriod,
                    canSelectNextPeriod: viewModel.canSelectNextPeriod,
                    previousPeriodTooltip: viewModel.previousPeriodTooltip,
                    nextPeriodTooltip: viewModel.nextPeriodTooltip,
                    onPreviousPeriod: viewModel.selectPreviousPeriod,
                    onNextPeriod: viewModel.selectNextPeriod,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  if (_showSummary)
                    FluidIntakeSummaryTable(
                      periodLabel: viewModel.selectedPeriodLabel,
                      avg: viewModel.periodAverageDailyMl,
                      min: viewModel.periodMinDailyMl,
                      max: viewModel.periodMaxDailyMl,
                      stdDev: viewModel.periodStdDevDailyMl,
                    )
                  else
                    FluidIntakeTrendChart(
                      days: viewModel.chartDays,
                      compact: true,
                    ),
                  const SizedBox(height: AppTheme.spacingSm),
                  FluidIntakePeriodSelector(
                    selected: viewModel.selectedPeriod,
                    onSelected: viewModel.selectPeriod,
                  ),
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
                          onPressed: _logFluid,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Log',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.logFluidIntake,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    if (viewModel.logs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingMd,
                        ),
                        child: Text(
                          'No water logged yet. Tap Log to add some.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.muted,
                          ),
                        ),
                      )
                    else
                      WeekGroupedHistoryList<FluidIntakeLog>(
                        readings: viewModel.logs,
                        recordedAt: (log) => log.recordedAt,
                        rowBuilder: (context, log) {
                          return FluidIntakeRecentCard(
                            log: log,
                            deltaMl: viewModel.changeVsPrevious(log),
                            onTap: () => _editLog(log),
                          );
                        },
                      ),
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

class _FluidSummaryStrip extends StatelessWidget {
  const _FluidSummaryStrip({
    required this.periodLabel,
    required this.value,
    required this.unit,
    required this.metaLabel,
    required this.showsPeriodNavigator,
    required this.canSelectPreviousPeriod,
    required this.canSelectNextPeriod,
    required this.previousPeriodTooltip,
    required this.nextPeriodTooltip,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
  });

  static const double _periodRowHeight = 36;
  static const double _valueRowHeight = 28;
  static const double _metaRowHeight = 16;

  final String periodLabel;
  final String? value;
  final String unit;
  final String? metaLabel;
  final bool showsPeriodNavigator;
  final bool canSelectPreviousPeriod;
  final bool canSelectNextPeriod;
  final String previousPeriodTooltip;
  final String nextPeriodTooltip;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;

  double get _totalHeight =>
      _periodRowHeight +
      2 +
      _valueRowHeight +
      (metaLabel != null ? 2 + _metaRowHeight : 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodStyle = theme.textTheme.labelMedium?.copyWith(
      color: AppTheme.muted,
      fontWeight: FontWeight.w600,
    );
    final valueStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppTheme.ink,
      height: 1.0,
      letterSpacing: -0.6,
    );
    final unitStyle = theme.textTheme.titleSmall?.copyWith(
      color: AppTheme.muted,
      fontWeight: FontWeight.w500,
    );
    final metaStyle = theme.textTheme.labelSmall?.copyWith(
      color: AppTheme.muted,
      fontWeight: FontWeight.w500,
      height: 1.1,
    );

    return SizedBox(
      height: _totalHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _periodRowHeight,
            child: Row(
              children: [
                _PeriodNavButton(
                  visible: showsPeriodNavigator,
                  tooltip: previousPeriodTooltip,
                  enabled: canSelectPreviousPeriod,
                  icon: Icons.chevron_left,
                  onPressed: onPreviousPeriod,
                ),
                Expanded(
                  child: Text(
                    periodLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: periodStyle,
                  ),
                ),
                _PeriodNavButton(
                  visible: showsPeriodNavigator,
                  tooltip: nextPeriodTooltip,
                  enabled: canSelectNextPeriod,
                  icon: Icons.chevron_right,
                  onPressed: onNextPeriod,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: _valueRowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value ?? '—', style: valueStyle),
                const SizedBox(width: 4),
                Text(unit, style: unitStyle),
              ],
            ),
          ),
          if (metaLabel != null) ...[
            const SizedBox(height: 2),
            SizedBox(
              height: _metaRowHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  metaLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PeriodNavButton extends StatelessWidget {
  const _PeriodNavButton({
    required this.visible,
    required this.tooltip,
    required this.enabled,
    required this.icon,
    required this.onPressed,
  });

  final bool visible;
  final String tooltip;
  final bool enabled;
  final IconData icon;
  final VoidCallback onPressed;

  static const double _size = _FluidSummaryStrip._periodRowHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: visible
          ? IconButton(
              tooltip: tooltip,
              onPressed: enabled ? onPressed : null,
              icon: Icon(icon, size: 22),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: _size, minHeight: _size),
            )
          : null,
    );
  }
}

class _SummaryGraphSelector extends StatelessWidget {
  const _SummaryGraphSelector({
    required this.isSummary,
    required this.onChanged,
  });

  final bool isSummary;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SelectorChip(
              label: 'Summary',
              selected: isSummary,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _SelectorChip(
              label: 'Graph',
              selected: !isSummary,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorChip extends StatelessWidget {
  const _SelectorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppTheme.cardSurface : AppTheme.muted,
                ),
          ),
        ),
      ),
    );
  }
}
