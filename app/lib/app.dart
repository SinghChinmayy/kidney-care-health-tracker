import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/database_holder.dart';
import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/data/services/auth_service.dart';
import 'package:app/data/services/connectivity_service.dart';
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
        Provider.value(value: appDatabase),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ConnectivityService()),
        ProxyProvider<AuthService, AuthRepository>(
          update: (_, authService, _) =>
              AuthRepository(authService: authService),
        ),
        ProxyProvider2<AppDatabase, ConnectivityService, PatientRepository>(
          update: (_, db, connectivity, _) => PatientRepository(
            db: db,
            isOnline: connectivity.isOnline,
            onWrite: () {},
          ),
        ),
        ProxyProvider2<AuthRepository, PatientRepository, VitalsRepository>(
          update: (_, auth, patients, _) => VitalsRepository(
            db: appDatabase,
            patientRepository: patients,
            currentAuthUserId: () => auth.currentSession?.user.id,
            onWrite: () {},
          ),
        ),
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
            vitalsRepository: context.read<VitalsRepository>(),
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProxyProvider<VitalsRepository, BloodPressureViewModel>(
          create: (context) => BloodPressureViewModel(
            vitalsRepository: context.read<VitalsRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? BloodPressureViewModel(vitalsRepository: repository),
        ),
        ChangeNotifierProxyProvider<VitalsRepository, BloodGlucoseViewModel>(
          create: (context) => BloodGlucoseViewModel(
            vitalsRepository: context.read<VitalsRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? BloodGlucoseViewModel(vitalsRepository: repository),
        ),
        ChangeNotifierProxyProvider<VitalsRepository, WeightViewModel>(
          create: (context) => WeightViewModel(
            vitalsRepository: context.read<VitalsRepository>(),
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
