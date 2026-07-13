import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/onboarding/views/caretaker_signup_view.dart';
import 'package:app/ui/features/onboarding/views/patient_signup_view.dart';
import 'package:flutter/material.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppScreenAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      size: 48,
                      color: AppTheme.ink,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Welcome to Kidney Care',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Choose your role so we can set up the right profile '
                      'and care tools for you.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.muted,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    AppOptionCard(
                      icon: Icons.person_outline,
                      iconSize: 32,
                      title: 'I am a patient',
                      description:
                          'Build your health profile, track vitals, dialysis, '
                          'and fluid goals.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PatientSignupView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    AppOptionCard(
                      icon: Icons.favorite_outline,
                      iconSize: 32,
                      title: 'I am a caretaker',
                      description:
                          'Support someone else\'s care. Patient linking comes '
                          'in a later release.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CaretakerSignupView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      'You can update profile details anytime after signup.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.muted,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
