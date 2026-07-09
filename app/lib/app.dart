import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/database_holder.dart';
import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/data/services/auth_service.dart';
import 'package:app/data/services/connectivity_service.dart';
import 'package:app/data/sync/sync_coordinator.dart';
import 'package:app/data/sync/sync_engine.dart';
import 'package:app/data/sync/sync_lifecycle_observer.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/auth/view_models/login_view_model.dart';
import 'package:app/ui/features/auth/views/auth_gate.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/onboarding/view_models/patient_signup_view_model.dart';
import 'package:app/ui/features/profile/view_models/profile_view_model.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
import 'package:app/ui/features/vitals/view_models/blood_pressure_view_model.dart';
import 'package:app/ui/features/vitals/view_models/fluid_intake_view_model.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KidneyCareApp extends StatelessWidget {
  const KidneyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: appDatabase),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ConnectivityService()),
        ProxyProvider2<AuthService, AppDatabase, AuthRepository>(
          update: (_, authService, db, _) => AuthRepository(
            authService: authService,
            db: db,
          ),
        ),
        ProxyProvider2<AppDatabase, AuthRepository, SyncEngine>(
          update: (_, db, auth, _) => SyncEngine(
            db: db,
            supabase: Supabase.instance.client,
            currentAuthUserId: () => auth.currentSession?.user.id,
          ),
        ),
        ProxyProvider<SyncEngine, SyncCoordinator>(
          update: (_, engine, _) => SyncCoordinator(engine: engine),
        ),
        ProxyProvider3<AppDatabase, ConnectivityService, SyncCoordinator,
            PatientRepository>(
          update: (_, db, connectivity, coordinator, _) => PatientRepository(
            db: db,
            isOnline: connectivity.isOnline,
            onWrite: coordinator.onDriftWrite,
          ),
        ),
        ProxyProvider3<AuthRepository, PatientRepository, SyncCoordinator,
            VitalsRepository>(
          update: (_, auth, patients, coordinator, _) => VitalsRepository(
            db: appDatabase,
            patientRepository: patients,
            currentAuthUserId: () => auth.currentSession?.user.id,
            onWrite: coordinator.onDriftWrite,
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
          ),
        ),
        ChangeNotifierProxyProvider2<AuthRepository, PatientRepository,
            ProfileViewModel>(
          create: (context) => ProfileViewModel(
            authRepository: context.read<AuthRepository>(),
            patientRepository: context.read<PatientRepository>(),
          ),
          update: (_, auth, patients, previous) =>
              previous ??
              ProfileViewModel(
                authRepository: auth,
                patientRepository: patients,
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
        ChangeNotifierProxyProvider<VitalsRepository, FluidIntakeViewModel>(
          create: (context) => FluidIntakeViewModel(
            vitalsRepository: context.read<VitalsRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? FluidIntakeViewModel(vitalsRepository: repository),
        ),
      ],
      child: SyncLifecycleObserver(
        child: MaterialApp(
          title: 'Kidney Care',
          theme: AppTheme.light,
          home: const AuthGate(),
        ),
      ),
    );
  }
}
