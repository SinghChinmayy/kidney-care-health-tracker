import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_form_layout.dart';
import 'package:app/ui/features/auth/view_models/login_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    return Scaffold(
      body: SafeArea(
        child: AppFormLayout(
          children: [
            const SizedBox(height: AppTheme.spacingXl),
            Icon(
              Icons.health_and_safety_outlined,
              size: 56,
              color: AppTheme.ink,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Kidney Care',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Track vitals and manage your kidney health',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    obscureText: viewModel.obscurePassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: viewModel.togglePasswordVisibility,
                        icon: Icon(
                          viewModel.obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: validatePassword,
                    onFieldSubmitted: (_) => _submit(viewModel),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => viewModel.forgotPassword(context),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  ElevatedButton(
                    onPressed: () => _submit(viewModel),
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextButton(
                    onPressed: () => viewModel.goToSignUp(context),
                    child: const Text("Don't have an account? Sign up"),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    TextButton(
                      onPressed: () => viewModel.skipToHome(context),
                      child: const Text('Skip to home (debug)'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(LoginViewModel viewModel) {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (_formKey.currentState?.validate() ?? false) {
      viewModel.signIn(context);
    }
  }
}
