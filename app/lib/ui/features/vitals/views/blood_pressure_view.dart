import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/vitals/view_models/blood_pressure_view_model.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_edit_sheet.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_hr_chart.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_period_selector.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_recent_card.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_summary_table.dart';
import 'package:app/ui/features/vitals/widgets/blood_pressure_trend_chart.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_sheets.dart';
import 'package:app/ui/features/vitals/widgets/week_grouped_history_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BloodPressureView extends StatefulWidget {
  const BloodPressureView({super.key});

  @override
  State<BloodPressureView> createState() => _BloodPressureViewState();
}

class _BloodPressureViewState extends State<BloodPressureView> {
  bool _showSummary = false;
  bool _showHeartRate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BloodPressureViewModel>().refresh();
    });
  }

  Future<void> _logBloodPressure() {
    final viewModel = context.read<BloodPressureViewModel>();
    return showBloodPressureLogSheet(
      context,
      onSaved: viewModel.refresh,
    );
  }

  Future<void> _editReading(BloodPressureReading reading) {
    final viewModel = context.read<BloodPressureViewModel>();
    return showBloodPressureEditSheet(
      context,
      reading: reading,
      viewModel: viewModel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BloodPressureViewModel>();
    final theme = Theme.of(context);
    final hero = viewModel.heroDisplayValue;
    final heroReading = viewModel.heroReading;
    final hasHrData =
        viewModel.chartDays.any((d) => d.heartRateBpm != null);

    return Scaffold(
      backgroundColor: AppTheme.bpBackground,
      appBar: const AppScreenAppBar(title: 'Blood Pressure'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logBloodPressure,
        tooltip: 'Log blood pressure',
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
                  // Summary / Graph toggle
                  _SummaryGraphSelector(
                    isSummary: _showSummary,
                    onChanged: (val) => setState(() {
                      _showSummary = val;
                      if (val) _showHeartRate = false;
                    }),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),

                  _BpSummaryStrip(
                    periodLabel: viewModel.selectedPeriodLabel,
                    value: hero,
                    unit: viewModel.heroUnit,
                    dateLabel: viewModel.heroDateLabel,
                    heartRateBpm: heroReading?.heartRateBpm,
                    showsPeriodNavigator: viewModel.showsPeriodNavigator,
                    canSelectPreviousPeriod: viewModel.canSelectPreviousPeriod,
                    canSelectNextPeriod: viewModel.canSelectNextPeriod,
                    previousPeriodTooltip: viewModel.previousPeriodTooltip,
                    nextPeriodTooltip: viewModel.nextPeriodTooltip,
                    onPreviousPeriod: viewModel.selectPreviousPeriod,
                    onNextPeriod: viewModel.selectNextPeriod,
                  ),

                  const SizedBox(height: AppTheme.spacingSm),

                  // Main view (Table or Graph Chart)
                  if (_showSummary)
                    BloodPressureSummaryTable(
                      periodLabel: viewModel.selectedPeriodLabel,
                      avgSys: viewModel.periodAverageSystolic,
                      minSys: viewModel.periodMinSystolic,
                      maxSys: viewModel.periodMaxSystolic,
                      stdDevSys: viewModel.periodStdDevSystolic,
                      avgDia: viewModel.periodAverageDiastolic,
                      minDia: viewModel.periodMinDiastolic,
                      maxDia: viewModel.periodMaxDiastolic,
                      stdDevDia: viewModel.periodStdDevDiastolic,
                    )
                  else ...[
                    if (hasHrData) ...[
                      _MetricSelector(
                        showHeartRate: _showHeartRate,
                        onChanged: (showHr) =>
                            setState(() => _showHeartRate = showHr),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                    ],
                    if (_showHeartRate)
                      BloodPressureHrChart(
                        days: viewModel.chartDays,
                        compact: true,
                        avgHr: viewModel.periodAverageHr,
                      )
                    else
                      BloodPressureTrendChart(
                        days: viewModel.chartDays,
                        compact: true,
                      ),
                  ],

                  const SizedBox(height: AppTheme.spacingSm),

                  BloodPressurePeriodSelector(
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
                          onPressed: _logBloodPressure,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Log',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.logBloodPressure,
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
                          'No blood pressure readings yet. Tap Log to add one.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.muted,
                          ),
                        ),
                      )
                    else
                      WeekGroupedHistoryList<BloodPressureReading>(
                        readings: viewModel.readings,
                        recordedAt: (reading) => reading.recordedAt,
                        rowBuilder: (context, reading) {
                          return BloodPressureRecentCard(
                            reading: reading,
                            deltaSystolic:
                                viewModel.changeVsPrevious(reading),
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

// ---------------------------------------------------------------------------
// Compact summary header (no card — sits on page background)
// ---------------------------------------------------------------------------

class _BpSummaryStrip extends StatelessWidget {
  const _BpSummaryStrip({
    required this.periodLabel,
    required this.value,
    required this.unit,
    required this.dateLabel,
    required this.heartRateBpm,
    required this.showsPeriodNavigator,
    required this.canSelectPreviousPeriod,
    required this.canSelectNextPeriod,
    required this.previousPeriodTooltip,
    required this.nextPeriodTooltip,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
  });

  static const double _periodRowHeight = 36;
  static const double _valueRowHeight = 32;

  final String periodLabel;
  final String? value;
  final String unit;
  final String? dateLabel;
  final int? heartRateBpm;
  final bool showsPeriodNavigator;
  final bool canSelectPreviousPeriod;
  final bool canSelectNextPeriod;
  final String previousPeriodTooltip;
  final String nextPeriodTooltip;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;

  String? get _metaCaption {
    final parts = <String>[
      if (dateLabel != null) dateLabel!,
      if (heartRateBpm != null) '$heartRateBpm bpm',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

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
    final metaStyle = theme.textTheme.labelMedium?.copyWith(
      color: AppTheme.muted,
      fontWeight: FontWeight.w500,
    );
    final meta = _metaCaption;

    return SizedBox(
      height: _periodRowHeight + 2 + _valueRowHeight,
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
                if (meta != null) ...[
                  const Spacer(),
                  Flexible(
                    child: Text(
                      meta,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: metaStyle,
                    ),
                  ),
                ],
              ],
            ),
          ),
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

  static const double _size = _BpSummaryStrip._periodRowHeight;

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

// ---------------------------------------------------------------------------
// Summary / Graph Top Pill Selector
// ---------------------------------------------------------------------------

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
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 7 : 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: compact ? 12 : null,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppTheme.background : AppTheme.muted,
                ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BP / Heart rate toggle (graph mode only)
// ---------------------------------------------------------------------------

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({
    required this.showHeartRate,
    required this.onChanged,
  });

  final bool showHeartRate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SelectorChip(
              label: 'Blood pressure',
              selected: !showHeartRate,
              compact: true,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _SelectorChip(
              label: 'Heart rate',
              selected: showHeartRate,
              compact: true,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}
