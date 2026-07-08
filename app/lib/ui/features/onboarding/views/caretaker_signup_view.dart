import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/core/widgets/app_form_layout.dart';
import 'package:app/ui/features/shell/views/app_shell_view.dart';
import 'package:flutter/material.dart';

class CaretakerSignupView extends StatefulWidget {
  const CaretakerSignupView({super.key});

  @override
  State<CaretakerSignupView> createState() => _CaretakerSignupViewState();
}

class _CaretakerSignupViewState extends State<CaretakerSignupView> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppScreenAppBar(title: 'Caretaker signup'),
      body: SafeArea(
        child: AppFormLayout(
          children: [
            Text(
              'Support a patient',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Caretaker accounts will link to a patient in a later release.',
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
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) =>
                        validateRequired(value, label: 'Full name'),
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
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Patient invite code',
                      hintText: 'Optional for now',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Create caretaker account'),
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
        MaterialPageRoute<void>(builder: (_) => const AppShellView()),
        (_) => false,
      );
    }
  }
}
