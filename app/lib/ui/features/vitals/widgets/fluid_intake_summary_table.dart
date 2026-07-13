import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class FluidIntakeSummaryTable extends StatelessWidget {
  const FluidIntakeSummaryTable({
    super.key,
    required this.periodLabel,
    this.avg,
    this.min,
    this.max,
    this.stdDev,
  });

  final String periodLabel;
  final double? avg;
  final double? min;
  final double? max;
  final double? stdDev;

  String _fmt(double? value, {int decimals = 0}) {
    if (value == null) {
      return '—';
    }
    return value.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardCornerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Text(
                    'Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ml / day',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
              Text(
                periodLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.logFluidIntake,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Row(
                  children: const [
                    _HeaderCell(label: 'Avg'),
                    _HeaderCell(label: 'Low'),
                    _HeaderCell(label: 'High'),
                    _HeaderCell(label: 'StdDev'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TableDataRow(
            label: 'H2O',
            avg: _fmt(avg),
            low: _fmt(min),
            high: _fmt(max),
            stdDev: _fmt(stdDev),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _TableDataRow extends StatelessWidget {
  const _TableDataRow({
    required this.label,
    required this.avg,
    required this.low,
    required this.high,
    required this.stdDev,
  });

  final String label;
  final String avg;
  final String low;
  final String high;
  final String stdDev;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _DataCell(
                  value: avg,
                  color: AppTheme.logFluidIntake,
                  isBold: true,
                ),
                _DataCell(
                  value: low,
                  color: const Color(0xFF009688),
                  isBold: true,
                ),
                _DataCell(
                  value: high,
                  color: const Color(0xFFE57373),
                  isBold: true,
                ),
                _DataCell(
                  value: stdDev,
                  color: const Color(0xFF455A64),
                  isBold: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell({
    required this.value,
    required this.color,
    required this.isBold,
  });

  final String value;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
      ),
    );
  }
}
