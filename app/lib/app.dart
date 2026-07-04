import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/mock_vitals_repository.dart';
import 'package:app/data/services/auth_service.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/auth/view_models/login_view_model.dart';
import 'package:app/ui/features/auth/views/auth_gate.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/onboarding/view_models/patient_signup_view_model.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
import 'package:app/ui/features/vitals/view_models/blood_pressure_view_model.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KidneyCareApp extends StatelessWidget {
  const KidneyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        ProxyProvider<AuthService, AuthRepository>(
          update: (_, authService, _) =>
              AuthRepository(authService: authService),
        ),
        Provider(create: (_) => MockVitalsRepository()),
        ChangeNotifierProvider(
          create: (context) => LoginViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PatientSignupViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(
            vitalsRepository: context.read<MockVitalsRepository>(),
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProxyProvider<MockVitalsRepository, BloodPressureViewModel>(
          create: (context) => BloodPressureViewModel(
            vitalsRepository: context.read<MockVitalsRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? BloodPressureViewModel(vitalsRepository: repository),
        ),
        ChangeNotifierProxyProvider<MockVitalsRepository, BloodGlucoseViewModel>(
          create: (context) => BloodGlucoseViewModel(
            vitalsRepository: context.read<MockVitalsRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? BloodGlucoseViewModel(vitalsRepository: repository),
        ),
        ChangeNotifierProxyProvider<MockVitalsRepository, WeightViewModel>(
          create: (context) => WeightViewModel(
            vitalsRepository: context.read<MockVitalsRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? WeightViewModel(vitalsRepository: repository),
        ),
      ],
      child: MaterialApp(
        title: 'Kidney Care',
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
