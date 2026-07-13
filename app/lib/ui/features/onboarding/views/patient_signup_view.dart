import 'package:app/domain/models/patient_preferences.dart';
import 'package:app/domain/models/patient_signup_profile.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/core/widgets/app_form_layout.dart';
import 'package:app/ui/features/onboarding/view_models/patient_signup_view_model.dart';
import 'package:app/ui/features/profile/utils/profile_formatters.dart';
import 'package:app/ui/features/profile/widgets/profile_option_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PatientSignupView extends StatefulWidget {
  const PatientSignupView({super.key});

  @override
  State<PatientSignupView> createState() => _PatientSignupViewState();
}

class _PatientSignupViewState extends State<PatientSignupView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  String? _selectedSex;
  String? _selectedCkdStage;
  String _dialysisType = 'none';
  List<int>? _dialysisDaysOfWeek;
  double? _heightCm;
  String _weightUnit = PatientPreferences.defaultWeightUnit;
  String _bloodGlucoseUnit = PatientPreferences.defaultBloodGlucoseUnit;
  int _dailyWaterGoalMl = PatientPreferences.defaultDailyWaterGoalMl;

  bool get _showsDialysisDays => _dialysisType != 'none';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PatientSignupViewModel>();
    final enabled = !viewModel.isLoading;

    return Scaffold(
      appBar: const AppScreenAppBar(title: 'Patient signup'),
      body: SafeArea(
        child: AppFormLayout(
          children: [
            Text(
              'Create your patient profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'These details match your in-app profile so vitals, dialysis, '
              'and fluid tracking work from day one.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionHeader(
                    title: 'Account',
                    subtitle: 'Used to sign in and sync your data.',
                  ),
                  TextFormField(
                    controller: _emailController,
                    enabled: enabled,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    controller: _passwordController,
                    enabled: enabled,
                    obscureText: viewModel.obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: enabled
                            ? viewModel.togglePasswordVisibility
                            : null,
                        icon: Icon(
                          viewModel.obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    controller: _confirmPasswordController,
                    enabled: enabled,
                    obscureText: viewModel.obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  const _SectionHeader(
                    title: 'About you',
                    subtitle: 'Basic identity details for your profile.',
                  ),
                  TextFormField(
                    controller: _firstNameController,
                    enabled: enabled,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.givenName],
                    decoration: const InputDecoration(labelText: 'First name'),
                    validator: (value) =>
                        validateRequired(value, label: 'First name'),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    controller: _lastNameController,
                    enabled: enabled,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.familyName],
                    decoration: const InputDecoration(labelText: 'Last name'),
                    validator: (value) =>
                        validateRequired(value, label: 'Last name'),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    controller: _dateOfBirthController,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.birthday],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                      DdMmYyyyInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      hintText: 'DD/MM/YYYY',
                    ),
                    validator: validateDateOfBirthDdMmYyyy,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSex,
                    decoration: const InputDecoration(labelText: 'Sex'),
                    items: [
                      for (final option in sexOptions)
                        DropdownMenuItem(value: option, child: Text(option)),
                    ],
                    onChanged: enabled
                        ? (value) => setState(() => _selectedSex = value)
                        : null,
                    validator: (value) =>
                        value == null ? 'Sex is required' : null,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  _PickerFormField(
                    label: 'Height',
                    valueText: formatHeightLabel(_heightCm),
                    isEmpty: _heightCm == null,
                    enabled: enabled,
                    validator: (_) =>
                        _heightCm == null ? 'Height is required' : null,
                    onTap: () => _pickHeight(),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  const _SectionHeader(
                    title: 'Kidney care',
                    subtitle: 'Helps personalize dialysis and vital insights.',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCkdStage,
                    decoration: const InputDecoration(labelText: 'CKD stage'),
                    items: [
                      for (final value in ckdStageOptions)
                        DropdownMenuItem(
                          value: value,
                          child: Text(formatCkdStageLabel(value)),
                        ),
                    ],
                    onChanged: enabled
                        ? (value) => setState(() => _selectedCkdStage = value)
                        : null,
                    validator: (value) =>
                        value == null ? 'CKD stage is required' : null,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  DropdownButtonFormField<String>(
                    initialValue: _dialysisType,
                    decoration: const InputDecoration(labelText: 'Dialysis'),
                    items: [
                      for (final value in dialysisTypeOptions)
                        DropdownMenuItem(
                          value: value,
                          child: Text(formatDialysisTypeLabel(value)),
                        ),
                    ],
                    onChanged: enabled
                        ? (value) {
                            if (value == null) return;
                            setState(() {
                              _dialysisType = value;
                              if (value == 'none') {
                                _dialysisDaysOfWeek = null;
                              }
                            });
                          }
                        : null,
                  ),
                  if (_showsDialysisDays) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    _PickerFormField(
                      label: 'Dialysis days',
                      valueText:
                          formatDialysisDaysOfWeekLabel(_dialysisDaysOfWeek),
                      isEmpty: _dialysisDaysOfWeek == null,
                      enabled: enabled,
                      validator: (_) {
                        if (!_showsDialysisDays) return null;
                        if (_dialysisDaysOfWeek == null) {
                          return 'Dialysis days are required';
                        }
                        return null;
                      },
                      onTap: () => _pickDialysisDays(),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingMd),
                  const _SectionHeader(
                    title: 'Preferences',
                    subtitle: 'Units and daily fluid target used across the app.',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _weightUnit,
                    decoration: const InputDecoration(labelText: 'Weight unit'),
                    items: [
                      for (final value in weightUnitOptions)
                        DropdownMenuItem(
                          value: value,
                          child: Text(formatWeightUnitLabel(value)),
                        ),
                    ],
                    onChanged: enabled
                        ? (value) {
                            if (value == null) return;
                            setState(() => _weightUnit = value);
                          }
                        : null,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  DropdownButtonFormField<String>(
                    initialValue: _bloodGlucoseUnit,
                    decoration:
                        const InputDecoration(labelText: 'Glucose unit'),
                    items: [
                      for (final value in bloodGlucoseUnitOptions)
                        DropdownMenuItem(
                          value: value,
                          child: Text(formatBloodGlucoseUnitLabel(value)),
                        ),
                    ],
                    onChanged: enabled
                        ? (value) {
                            if (value == null) return;
                            setState(() => _bloodGlucoseUnit = value);
                          }
                        : null,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  _PickerFormField(
                    label: 'Daily fluid limit',
                    valueText: formatDailyWaterGoalLabel(_dailyWaterGoalMl),
                    isEmpty: false,
                    enabled: enabled,
                    onTap: () => _pickDailyWaterGoal(),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  ElevatedButton(
                    onPressed: enabled ? _submit : null,
                    child: viewModel.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create account'),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickHeight() async {
    final selected = await showProfileHeightPickerSheet(
      context,
      initialHeightCm: _heightCm,
    );
    if (!mounted || selected == null) return;
    setState(() => _heightCm = selected);
  }

  Future<void> _pickDialysisDays() async {
    final selected = await showProfileDialysisDaysPickerSheet(
      context,
      initialDays: _dialysisDaysOfWeek,
    );
    if (!mounted || selected == null) return;
    setState(() => _dialysisDaysOfWeek = selected);
  }

  Future<void> _pickDailyWaterGoal() async {
    final selected = await showProfileWaterGoalPickerSheet(
      context,
      initialGoalMl: _dailyWaterGoalMl,
    );
    if (!mounted || selected == null) return;
    setState(() => _dailyWaterGoalMl = selected);
  }

  Future<void> _submit() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final dateOfBirth = parseDdMmYyyy(_dateOfBirthController.text);
    if (dateOfBirth == null) {
      return;
    }

    final profile = PatientSignupProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: dateOfBirth,
      sex: _selectedSex!,
      ckdStage: _selectedCkdStage!,
      dialysisType: _dialysisType,
      dialysisDaysOfWeek:
          _dialysisType == 'none' ? null : _dialysisDaysOfWeek,
      heightCm: _heightCm,
      weightUnit: _weightUnit,
      bloodGlucoseUnit: _bloodGlucoseUnit,
      dailyWaterGoalMl: _dailyWaterGoalMl,
    );

    final viewModel = context.read<PatientSignupViewModel>();
    final result = await viewModel.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      profile: profile,
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      final message = viewModel.errorMessage;
      if (message != null) {
        showPlaceholderSnackBar(context, message);
      }
      return;
    }

    if (result.needsEmailConfirmation) {
      showPlaceholderSnackBar(
        context,
        'Account created. Check your email to confirm, then sign in. '
        'You can finish your profile after signing in.',
      );
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                ),
          ),
        ],
      ),
    );
  }
}

class _PickerFormField extends FormField<void> {
  _PickerFormField({
    required String label,
    required String valueText,
    required bool isEmpty,
    required VoidCallback onTap,
    bool enabled = true,
    super.validator,
  }) : super(
          builder: (state) {
            return InkWell(
              onTap: enabled
                  ? () {
                      onTap();
                      state.didChange(null);
                    }
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
              child: InputDecorator(
                isEmpty: isEmpty,
                decoration: InputDecoration(
                  labelText: label,
                  errorText: state.errorText,
                  suffixIcon: const Icon(Icons.expand_more),
                  enabled: enabled,
                ),
                child: Text(
                  isEmpty ? 'Not set' : valueText,
                  style: Theme.of(state.context).textTheme.bodyMedium?.copyWith(
                        color: isEmpty ? AppTheme.muted : AppTheme.ink,
                      ),
                ),
              ),
            );
          },
        );
}
