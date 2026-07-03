import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/patient_repository.dart';
import '../../theme/app_theme.dart';

/// One-time profile-completion screen shown when a signed-in patient's
/// `full_name` is still NULL — i.e. the signup bootstrap trigger created
/// the row but the user hasn't filled in their profile yet (see
/// `planning/sync/v0/stage-1.md` §7.2, §12.1).
///
/// Layout follows the same centered-form conventions as the login/sign-up
/// screens (`docs/Design/design.md` §2.3/§3.1).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onComplete, super.key});

  /// Called after the profile is saved so the caller (AuthGate) can reload
  /// the patient and route to the main app.
  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

const List<String> _ckdStages = [
  'stage_1',
  'stage_2',
  'stage_3a',
  'stage_3b',
  'stage_4',
  'stage_5',
  'dialysis',
  'transplant',
];

const List<String> _dialysisTypes = ['none', 'hemodialysis', 'peritoneal'];

const List<String> _sexOptions = ['female', 'male', 'other'];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _heightController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _sex;
  String? _ckdStage;
  String _dialysisType = 'none';
  bool _isSubmitting = false;

  late final PatientRepository _patientRepository;

  @override
  void initState() {
    super.initState();
    _patientRepository = PatientRepository(Supabase.instance.client);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your full name';
    }
    return null;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 40),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _patientRepository.updateProfile(
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _dateOfBirth,
        sex: _sex,
        ckdStage: _ckdStage,
        dialysisType: _dialysisType,
        heightCm: _heightController.text.trim().isEmpty
            ? null
            : double.tryParse(_heightController.text.trim()),
      );
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not save your profile: $e')),
        );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingLg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Complete your profile',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Just a few details so we can personalize your tracking.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                    TextFormField(
                      controller: _fullNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: _validateFullName,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    InkWell(
                      onTap: _pickDateOfBirth,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of birth (optional)',
                        ),
                        child: Text(
                          _dateOfBirth == null
                              ? 'Select a date'
                              : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    DropdownButtonFormField<String>(
                      initialValue: _sex,
                      decoration: const InputDecoration(
                        labelText: 'Sex (optional)',
                      ),
                      items: _sexOptions
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setState(() => _sex = value),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    DropdownButtonFormField<String>(
                      initialValue: _ckdStage,
                      decoration: const InputDecoration(
                        labelText: 'CKD stage (optional)',
                      ),
                      items: _ckdStages
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setState(() => _ckdStage = value),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    DropdownButtonFormField<String>(
                      initialValue: _dialysisType,
                      decoration: const InputDecoration(
                        labelText: 'Dialysis type',
                      ),
                      items: _dialysisTypes
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _dialysisType = value ?? 'none'),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Height in cm (optional)',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSave,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save and continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
