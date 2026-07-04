import 'package:app/ui/core/widgets/app_form_layout.dart';
import 'package:app/ui/features/home/views/home_view.dart';
import 'package:app/ui/features/onboarding/views/onboarding_view.dart';
import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  bool _obscurePassword = true;

  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void signIn(BuildContext context) {
    _goToHome(context);
  }

  void skipToHome(BuildContext context) {
    _goToHome(context);
  }

  void _goToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeView()),
    );
  }

  void goToSignUp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OnboardingView()),
    );
  }

  void forgotPassword(BuildContext context) {
    showPlaceholderSnackBar(context, 'Password reset coming soon.');
  }
}
