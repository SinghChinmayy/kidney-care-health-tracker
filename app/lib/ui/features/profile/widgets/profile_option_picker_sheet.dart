import 'package:app/debug/agent_debug_log.dart';
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
    isScrollControlled: true,
    sheetAnimationStyle: AnimationStyle.noAnimation,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
          ),
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
                Flexible(
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppTheme.ink)
                            : null,
                        onTap: () =>
                            Navigator.of(sheetContext).pop(option.value),
                      );
                    },
                  ),
                ),
              ],
            ),
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
    sheetAnimationStyle: AnimationStyle.noAnimation,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return _HeightPickerSheet(initialHeightCm: initialHeightCm);
    },
  );
}

class ProfileNameEditResult {
  const ProfileNameEditResult({
    required this.firstName,
    required this.lastName,
  });

  final String? firstName;
  final String? lastName;
}

Future<ProfileNameEditResult?> showProfileNamePickerSheet(
  BuildContext context, {
  String? initialFirstName,
  String? initialLastName,
  int? debugTapAt,
}) {
  // #region agent log
  agentDebugLog(
    hypothesisId: 'F',
    location: 'profile_option_picker_sheet.dart:showProfileNamePickerSheet',
    message: 'name_sheet_show_called',
    data: {
      'debugTapAt': debugTapAt,
      'sinceTapMs': debugTapAt == null
          ? null
          : DateTime.now().millisecondsSinceEpoch - debugTapAt,
      'sheetAnimationStyle': 'noAnimation',
      'autofocus': true,
    },
    runId: 'snap-fix',
  );
  // #endregion
  var builderCallCount = 0;
  return showModalBottomSheet<ProfileNameEditResult>(
    context: context,
    isScrollControlled: true,
    sheetAnimationStyle: AnimationStyle.noAnimation,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      builderCallCount += 1;
      // #region agent log
      agentDebugLog(
        hypothesisId: 'F',
        location: 'profile_option_picker_sheet.dart:name_sheet_builder',
        message: 'name_sheet_builder',
        data: {
          'builderCallCount': builderCallCount,
          'sinceTapMs': debugTapAt == null
              ? null
              : DateTime.now().millisecondsSinceEpoch - debugTapAt,
          'viewInsetsBottom': MediaQuery.viewInsetsOf(sheetContext).bottom,
        },
        runId: 'snap-fix',
      );
      // #endregion
      return _NamePickerSheet(
        initialFirstName: initialFirstName,
        initialLastName: initialLastName,
        debugTapAt: debugTapAt,
      );
    },
  );
}

class _NamePickerSheet extends StatefulWidget {
  const _NamePickerSheet({
    this.initialFirstName,
    this.initialLastName,
    this.debugTapAt,
  });

  final String? initialFirstName;
  final String? initialLastName;
  final int? debugTapAt;

  @override
  State<_NamePickerSheet> createState() => _NamePickerSheetState();
}

class _NamePickerSheetState extends State<_NamePickerSheet> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  String? _errorText;
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.initialFirstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.initialLastName ?? '',
    );
    // #region agent log
    agentDebugLog(
      hypothesisId: 'F',
      location: 'profile_option_picker_sheet.dart:_NamePickerSheetState.initState',
      message: 'name_sheet_init_autofocus',
      data: {
        'autofocus': true,
        'sheetAnimationStyle': 'noAnimation',
        'sinceTapMs': widget.debugTapAt == null
            ? null
            : DateTime.now().millisecondsSinceEpoch - widget.debugTapAt!,
      },
      runId: 'snap-fix',
    );
    // #endregion
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _submit() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (firstName.isEmpty) {
      setState(() => _errorText = 'Enter a first name.');
      return;
    }
    Navigator.of(context).pop(
      ProfileNameEditResult(
        firstName: firstName,
        lastName: lastName.isEmpty ? null : lastName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    _buildCount += 1;
    // #region agent log
    agentDebugLog(
      hypothesisId: 'F',
      location: 'profile_option_picker_sheet.dart:_NamePickerSheetState.build',
      message: 'name_sheet_build',
      data: {
        'buildCount': _buildCount,
        'viewInsetsBottom': insetsBottom,
        'sinceTapMs': widget.debugTapAt == null
            ? null
            : DateTime.now().millisecondsSinceEpoch - widget.debugTapAt!,
      },
      runId: 'snap-fix',
    );
    // #endregion
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingSm,
        right: AppTheme.spacingSm,
        top: AppTheme.spacingSm,
        bottom: insetsBottom + AppTheme.spacingSm,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Name', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _firstNameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'First name',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Last name',
              ),
              textInputAction: TextInputAction.done,
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
      ),
    );
  }
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
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacingSm,
      ),
      child: SingleChildScrollView(
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
      ),
    );
  }
}

Future<int?> showProfileWaterGoalPickerSheet(
  BuildContext context, {
  int? initialGoalMl,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    sheetAnimationStyle: AnimationStyle.noAnimation,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return _WaterGoalPickerSheet(initialGoalMl: initialGoalMl);
    },
  );
}

class _WaterGoalPickerSheet extends StatefulWidget {
  const _WaterGoalPickerSheet({this.initialGoalMl});

  final int? initialGoalMl;

  @override
  State<_WaterGoalPickerSheet> createState() => _WaterGoalPickerSheetState();
}

class _WaterGoalPickerSheetState extends State<_WaterGoalPickerSheet> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: '${widget.initialGoalMl ?? 1200}',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 100 || value > 5000) {
      setState(() => _errorText = 'Enter a limit between 100 and 5000 ml.');
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
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacingSm,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Daily fluid limit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limit (ml)',
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
      ),
    );
  }
}

Future<List<int>?> showProfileDialysisDaysPickerSheet(
  BuildContext context, {
  List<int>? initialDays,
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    sheetAnimationStyle: AnimationStyle.noAnimation,
    backgroundColor: AppTheme.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return _DialysisDaysPickerSheet(initialDays: initialDays);
    },
  );
}

class _DialysisDaysPickerSheet extends StatefulWidget {
  const _DialysisDaysPickerSheet({this.initialDays});

  final List<int>? initialDays;

  @override
  State<_DialysisDaysPickerSheet> createState() =>
      _DialysisDaysPickerSheetState();
}

class _DialysisDaysPickerSheetState extends State<_DialysisDaysPickerSheet> {
  static const _dayOptions = <(int, String)>[
    (1, 'Monday'),
    (2, 'Tuesday'),
    (3, 'Wednesday'),
    (4, 'Thursday'),
    (5, 'Friday'),
    (6, 'Saturday'),
    (7, 'Sunday'),
  ];

  late final Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...?widget.initialDays};
  }

  void _toggle(int day) {
    setState(() {
      if (_selected.contains(day)) {
        _selected.remove(day);
      } else {
        _selected.add(day);
      }
    });
  }

  void _submit() {
    final days = _selected.toList()..sort();
    Navigator.of(context).pop(days);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
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
              Text(
                'Dialysis days',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              for (final (day, label) in _dayOptions)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selected.contains(day),
                  title: Text(label),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (_) => _toggle(day),
                ),
              const SizedBox(height: AppTheme.spacingSm),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
