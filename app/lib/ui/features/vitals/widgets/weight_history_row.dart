import 'package:app/domain/models/weight_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';

const _historyRowMaxWidth = 720.0;
const _compactHistoryRowMinWidth = 360.0;

class WeightHistoryRow extends StatelessWidget {
  const WeightHistoryRow({
    super.key,
    required this.reading,
    required this.onTap,
  });

  final WeightReading reading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bodyMedium = Theme.of(context).textTheme.bodyMedium;
    final timingLabel = formatDialysisTimingLabel(reading.dialysisTiming);
    final contextLabel = reading.weightContext == null ||
            reading.weightContext!.isEmpty
        ? null
        : formatWeightContextLabel(reading.weightContext!);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingXs,
              vertical: AppTheme.spacingXs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < _compactHistoryRowMinWidth;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: compact ? 4 : 3,
                          child: _HistorySection(
                            child: Text(
                              reading.displayValue,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        const _HistorySectionGutter(),
                        Expanded(
                          flex: compact ? 3 : 2,
                          child: _HistorySection(
                            child: Text(
                              formatHistoryTime(reading.recordedAt),
                              style: bodyMedium,
                            ),
                          ),
                        ),
                        const _HistorySectionGutter(),
                        Expanded(
                          flex: compact ? 5 : 4,
                          child: _HistorySection(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (contextLabel != null) ...[
                                  Text(
                                    contextLabel,
                                    style: bodyMedium?.copyWith(
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  timingLabel,
                                  style: bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (reading.notes != null && reading.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  Padding(
                    padding: const EdgeInsets.only(left: AppTheme.spacingXs),
                    child: Text(
                      reading.notes!,
                      style: bodyMedium?.copyWith(color: AppTheme.muted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Spacing between history columns — no visible divider.
class _HistorySectionGutter extends StatelessWidget {
  const _HistorySectionGutter();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: AppTheme.spacingSm);
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Keeps history rows readable on large screens.
class WeightHistoryListContainer extends StatelessWidget {
  const WeightHistoryListContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _historyRowMaxWidth),
        child: child,
      ),
    );
  }
}
