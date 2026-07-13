import 'package:app/domain/models/weight_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_sheets.dart';
import 'package:app/ui/features/vitals/widgets/weight_edit_sheet.dart';
import 'package:app/ui/features/vitals/widgets/weight_period_selector.dart';
import 'package:app/ui/features/vitals/widgets/weight_recent_card.dart';
import 'package:app/ui/features/vitals/widgets/weight_summary_table.dart';
import 'package:app/ui/features/vitals/widgets/weight_trend_chart.dart';
import 'package:app/ui/features/vitals/widgets/week_grouped_history_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeightView extends StatefulWidget {
  const WeightView({super.key});

  @override
  State<WeightView> createState() => _WeightViewState();
}

class _WeightViewState extends State<WeightView> {
  bool _showSummary = false;

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

    return Scaffold(
      backgroundColor: AppTheme.bpBackground,
      appBar: const AppScreenAppBar(title: 'Weight'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logWeight,
        tooltip: 'Log weight',
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
                  _WeightSummaryStrip(
                    periodLabel: viewModel.selectedPeriodLabel,
                    value: heroKg?.toStringAsFixed(1),
                    unit: 'kg',
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
                    WeightSummaryTable(
                      periodLabel: viewModel.selectedPeriodLabel,
                      avg: viewModel.periodAverageKg,
                      min: viewModel.periodMinKg,
                      max: viewModel.periodMaxKg,
                      stdDev: viewModel.periodStdDevKg,
                    )
                  else
                    WeightTrendChart(
                      days: viewModel.chartDays,
                      compact: true,
                    ),
                  const SizedBox(height: AppTheme.spacingSm),
                  WeightPeriodSelector(
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
                          onPressed: _logWeight,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Log',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.logWeight,
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
                          'No weight readings yet. Tap Log to add one.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.muted,
                          ),
                        ),
                      )
                    else
                      WeekGroupedHistoryList<WeightReading>(
                        readings: viewModel.readings,
                        recordedAt: (reading) => reading.recordedAt,
                        rowBuilder: (context, reading) {
                          return WeightRecentCard(
                            reading: reading,
                            deltaKg: viewModel.changeVsPrevious(reading),
                            onTap: () => _editReading(reading),
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

class _WeightSummaryStrip extends StatelessWidget {
  const _WeightSummaryStrip({
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

  static const double _size = _WeightSummaryStrip._periodRowHeight;

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
                  color: selected ? AppTheme.background : AppTheme.muted,
                ),
          ),
        ),
      ),
    );
  }
}
