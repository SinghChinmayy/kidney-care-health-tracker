import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/core/widgets/app_form_layout.dart';
import 'package:app/ui/features/home/views/home_view.dart';
import 'package:flutter/material.dart';

class PatientSignupView extends StatefulWidget {
  const PatientSignupView({super.key});

  @override
  State<PatientSignupView> createState() => _PatientSignupViewState();
}

class _PatientSignupViewState extends State<PatientSignupView> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  static const _ckdStages = [
    'Stage 1',
    'Stage 2',
    'Stage 3a',
    'Stage 3b',
    'Stage 4',
    'Stage 5',
  ];

  static const _sexOptions = ['Female', 'Male', 'Other', 'Prefer not to say'];

  String? _selectedCkdStage;
  String? _selectedSex;

  @override
  Widget build(BuildContext context) {
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
              'Profile fields match the patient record in the database.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'First name'),
                    validator: (value) =>
                        validateRequired(value, label: 'First name'),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Last name'),
                    validator: (value) =>
                        validateRequired(value, label: 'Last name'),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      hintText: 'YYYY-MM-DD',
                    ),
                    validator: validateRequired,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSex,
                    decoration: const InputDecoration(labelText: 'Sex'),
                    items: _sexOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedSex = value),
                    validator: (value) =>
                        value == null ? 'Sex is required' : null,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCkdStage,
                    decoration: const InputDecoration(labelText: 'CKD stage'),
                    items: _ckdStages
                        .map(
                          (stage) => DropdownMenuItem(
                            value: stage,
                            child: Text(stage),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCkdStage = value),
                    validator: (value) =>
                        value == null ? 'CKD stage is required' : null,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeView()),
        (_) => false,
      );
    }
  }
}
