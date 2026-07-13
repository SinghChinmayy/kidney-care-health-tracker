import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_form_layout.dart';
import 'package:app/ui/features/auth/view_models/login_view_model.dart';
import 'package:app/ui/features/auth/widgets/google_sign_in_button.dart';
import 'package:app/ui/features/onboarding/views/onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !viewModel.isLoading,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: viewModel.obscurePassword,
                    textInputAction: TextInputAction.done,
                    enabled: !viewModel.isLoading,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : viewModel.togglePasswordVisibility,
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
                      onPressed: viewModel.isLoading
                          ? null
                          : () => showPlaceholderSnackBar(
                                context,
                                'Password reset coming soon.',
                              ),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  ElevatedButton(
                    onPressed:
                        viewModel.isLoading ? null : () => _submit(viewModel),
                    child: viewModel.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  const _OrDivider(),
                  const SizedBox(height: AppTheme.spacingSm),
                  GoogleSignInButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => showPlaceholderSnackBar(
                              context,
                              'Google sign-in coming soon.',
                            ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  OutlinedButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => showPlaceholderSnackBar(
                              context,
                              'Guest login coming soon.',
                            ),
                    style: AppTheme.secondaryButtonStyle(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        SizedBox(width: AppTheme.spacingXs),
                        Text('Continue as guest'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const OnboardingView(),
                              ),
                            );
                          },
                    child: const Text("Don't have an account? Sign up"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(LoginViewModel viewModel) async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final success = await viewModel.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || success) {
      return;
    }

    final message = viewModel.errorMessage;
    if (message != null) {
      showPlaceholderSnackBar(context, message);
    }
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.muted,
        );
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.muted)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXs),
          child: Text('or', style: muted),
        ),
        const Expanded(child: Divider(color: AppTheme.muted)),
      ],
    );
  }
}
