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
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('DAY TYPE', style: labelStyle),
        const SizedBox(height: AppTheme.spacingXs),
        _OptionRow(
          options: const [
            _PickerOption(
              value: dialysisTimingNonDialysis,
              label: 'Non-dialysis day',
            ),
            _PickerOption(value: _dialysisDayMode, label: 'Dialysis day'),
          ],
          selectedValue:
              _isDialysisDay ? _dialysisDayMode : dialysisTimingNonDialysis,
          accentColor: accentColor,
          onSelected: (value) {
            if (value == dialysisTimingNonDialysis) {
              onDialysisTimingChanged(dialysisTimingNonDialysis);
            } else if (value == _dialysisDayMode) {
              onDialysisTimingChanged(dialysisTimingPreDialysis);
            }
          },
        ),
        if (_isDialysisDay) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Text('TIMING', style: labelStyle),
          const SizedBox(height: AppTheme.spacingXs),
          _OptionRow(
            options: const [
              _PickerOption(
                value: dialysisTimingPreDialysis,
                label: 'Pre-dialysis',
              ),
              _PickerOption(
                value: dialysisTimingPostDialysis,
                label: 'Post-dialysis',
              ),
            ],
            selectedValue: dialysisTiming,
            accentColor: accentColor,
            onSelected: (value) {
              if (value != null) {
                onDialysisTimingChanged(value);
              }
            },
          ),
        ],
        const SizedBox(height: AppTheme.spacingMd),
        Text('CONTEXT (OPTIONAL)', style: labelStyle),
        const SizedBox(height: AppTheme.spacingXs),
        _OptionRow(
          options: [
            const _PickerOption(value: null, label: 'None'),
            ...weightContextOptions.map(
              (option) => _PickerOption(
                value: option,
                label: formatWeightContextLabel(option),
              ),
            ),
          ],
          selectedValue: weightContext,
          accentColor: accentColor,
          onSelected: onWeightContextChanged,
        ),
      ],
    );
  }
}

class _PickerOption {
  const _PickerOption({required this.value, required this.label});

  final String? value;
  final String label;
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.options,
    required this.selectedValue,
    required this.accentColor,
    required this.onSelected,
  });

  final List<_PickerOption> options;
  final String? selectedValue;
  final Color accentColor;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacingXs,
      runSpacing: AppTheme.spacingXs,
      children: options.map((option) {
        final isSelected = selectedValue == option.value;
        return OutlinedButton(
          onPressed: () => onSelected(option.value),
          style: OutlinedButton.styleFrom(
            foregroundColor: isSelected ? accentColor : AppTheme.ink,
            backgroundColor: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : Colors.transparent,
            side: BorderSide(
              color: isSelected ? accentColor : AppTheme.muted.withValues(alpha: 0.4),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: AppTheme.spacingXs,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
            ),
          ),
          child: Text(option.label),
        );
      }).toList(),
    );
  }
}
