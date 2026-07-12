import 'package:app/domain/models/weight_reading_options.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';

const _dialysisDayMode = 'dialysis_day';

class WeightDialysisPicker extends StatelessWidget {
  const WeightDialysisPicker({
    super.key,
    required this.dialysisTiming,
    required this.weightContext,
    required this.onDialysisTimingChanged,
    required this.onWeightContextChanged,
    this.accentColor = AppTheme.logWeight,
  });

  final String dialysisTiming;
  final String? weightContext;
  final ValueChanged<String> onDialysisTimingChanged;
  final ValueChanged<String?> onWeightContextChanged;
  final Color accentColor;

  bool get _isDialysisDay => dialysisTiming != dialysisTimingNonDialysis;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTheme.muted,
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Day type', style: labelStyle),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: dialysisTimingNonDialysis,
              label: Text('Non-dialysis'),
            ),
            ButtonSegment(
              value: _dialysisDayMode,
              label: Text('Dialysis'),
            ),
          ],
          selected: {
            _isDialysisDay ? _dialysisDayMode : dialysisTimingNonDialysis,
          },
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return accentColor;
              return AppTheme.ink;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return accentColor.withValues(alpha: 0.12);
              }
              return Colors.transparent;
            }),
          ),
          onSelectionChanged: (selected) {
            final value = selected.first;
            if (value == dialysisTimingNonDialysis) {
              onDialysisTimingChanged(dialysisTimingNonDialysis);
            } else {
              onDialysisTimingChanged(dialysisTimingPreDialysis);
            }
          },
        ),
        if (_isDialysisDay) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Text('Timing', style: labelStyle),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: dialysisTimingPreDialysis,
                label: Text('Pre'),
              ),
              ButtonSegment(
                value: dialysisTimingPostDialysis,
                label: Text('Post'),
              ),
            ],
            selected: {dialysisTiming},
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return accentColor;
                return AppTheme.ink;
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return accentColor.withValues(alpha: 0.12);
                }
                return Colors.transparent;
              }),
            ),
            onSelectionChanged: (selected) {
              onDialysisTimingChanged(selected.first);
            },
          ),
        ],
        const SizedBox(height: AppTheme.spacingSm),
        Text('Context', style: labelStyle),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _ContextChip(
              label: 'None',
              selected: weightContext == null,
              accentColor: accentColor,
              onTap: () => onWeightContextChanged(null),
            ),
            ...weightContextOptions.map(
              (option) => _ContextChip(
                label: formatWeightContextLabel(option),
                selected: weightContext == option,
                accentColor: accentColor,
                onTap: () => onWeightContextChanged(option),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      selectedColor: accentColor.withValues(alpha: 0.14),
      side: BorderSide(
        color: selected
            ? accentColor.withValues(alpha: 0.55)
            : AppTheme.muted.withValues(alpha: 0.28),
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? accentColor : AppTheme.ink,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
      onSelected: (_) => onTap(),
    );
  }
}
