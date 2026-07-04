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
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Get started',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Choose how you will use Kidney Care.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              AppOptionCard(
                icon: Icons.person_outline,
                iconSize: 32,
                title: 'Patient signup',
                description:
                    'Create a profile to track your vitals and kidney health.',
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
                title: 'Caretaker signup',
                description:
                    'Support a patient by viewing and helping log their vitals.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CaretakerSignupView(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
