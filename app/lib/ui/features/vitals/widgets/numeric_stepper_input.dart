import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumericStepperInput extends StatefulWidget {
  const NumericStepperInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
    this.max = 999,
    this.decimals = 0,
    this.accentColor = AppTheme.logWeight,
    this.unitSuffix,
    this.allowDirectInput = false,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double max;
  final int decimals;
  final Color accentColor;
  final String? unitSuffix;
  final bool allowDirectInput;

  @override
  State<NumericStepperInput> createState() => _NumericStepperInputState();
}

class _NumericStepperInputState extends State<NumericStepperInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant NumericStepperInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      return;
    }

    _commitText(_controller.text);
  }

  String _formatValue(double value) {
    if (widget.decimals == 0) {
      return value.round().toString();
    }
    return value.toStringAsFixed(widget.decimals);
  }

  double _round(double next) {
    if (widget.decimals == 0) {
      return next.roundToDouble();
    }
    final factor = _pow10(widget.decimals);
    return (next * factor).roundToDouble() / factor;
  }

  double _pow10(int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  void _commitText(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null) {
      _controller.text = _formatValue(widget.value);
      return;
    }

    final clamped = _round(parsed.clamp(widget.min, widget.max));
    _controller.text = _formatValue(clamped);
    if (clamped != widget.value) {
      widget.onChanged(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Container(
          height: 2,
          color: widget.accentColor,
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepperButton(
              icon: Icons.remove,
              onPressed: widget.value - widget.step >= widget.min
                  ? () => widget.onChanged(_round(widget.value - widget.step))
                  : null,
            ),
            const SizedBox(width: AppTheme.spacingMd),
            SizedBox(
              width: 140,
              child: widget.allowDirectInput
                  ? TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,1}$'),
                        ),
                      ],
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                          ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: _commitText,
                      onEditingComplete: () {
                        _commitText(_controller.text);
                        _focusNode.unfocus();
                      },
                    )
                  : Text(
                      widget.unitSuffix == null
                          ? _formatValue(widget.value)
                          : '${_formatValue(widget.value)} ${widget.unitSuffix}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            _StepperButton(
              icon: Icons.add,
              onPressed: widget.value + widget.step <= widget.max
                  ? () => widget.onChanged(_round(widget.value + widget.step))
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.ink,
          side: BorderSide(
            color: onPressed == null
                ? AppTheme.muted.withValues(alpha: 0.4)
                : AppTheme.ink,
          ),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
          ),
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }
}
