import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProfilePickerOption {
  const ProfilePickerOption({
    required this.value,
    required this.label,
  });

  final String? value;
  final String label;
}

Future<String?> showProfileOptionPickerSheet(
  BuildContext context, {
  required String title,
  required List<ProfilePickerOption> options,
  required String? selectedValue,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    backgroundColor: AppTheme.background,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingSm,
            AppTheme.spacingXs,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: AppTheme.spacingSm),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: AppTheme.muted.withValues(alpha: 0.2),
                  ),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option.value == selectedValue;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        option.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppTheme.ink)
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(option.value),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<double?> showProfileHeightPickerSheet(
  BuildContext context, {
  double? initialHeightCm,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.background,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return _HeightPickerSheet(initialHeightCm: initialHeightCm);
    },
  );
}

class _HeightPickerSheet extends StatefulWidget {
  const _HeightPickerSheet({this.initialHeightCm});

  final double? initialHeightCm;

  @override
  State<_HeightPickerSheet> createState() => _HeightPickerSheetState();
}

class _HeightPickerSheetState extends State<_HeightPickerSheet> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialHeightCm;
    _controller = TextEditingController(
      text: initial == null
          ? ''
          : initial == initial.roundToDouble()
              ? initial.toStringAsFixed(0)
              : initial.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value < 50 || value > 250) {
      setState(() => _errorText = 'Enter height between 50 and 250 cm.');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingSm,
        right: AppTheme.spacingSm,
        top: AppTheme.spacingSm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Height', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          TextFormField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
            ),
            onFieldSubmitted: (_) => _submit(),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(_errorText!, style: TextStyle(color: AppTheme.error)),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
