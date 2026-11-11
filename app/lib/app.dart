import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/database_holder.dart';
import 'package:app/data/repositories/active_patient_notifier.dart';
import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/data/repositories/medications_repository.dart';
import 'package:app/data/repositories/patient_medication_schedule_repository.dart';
import 'package:app/data/repositories/patient_repository.dart';
import 'package:app/data/repositories/sharing_repository.dart';
import 'package:app/data/repositories/vitals_repository.dart';
import 'package:app/data/services/auth_service.dart';
import 'package:app/data/services/connectivity_service.dart';
import 'package:app/data/services/patient_access_remote.dart';
import 'package:app/data/sync/sync_coordinator.dart';
import 'package:app/data/sync/sync_engine.dart';
import 'package:app/data/sync/sync_lifecycle_observer.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/auth/view_models/login_view_model.dart';
import 'package:app/ui/features/auth/views/auth_gate.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/journal/view_models/journal_view_model.dart';
import 'package:app/ui/features/medications/view_models/medications_view_model.dart';
import 'package:app/ui/features/onboarding/view_models/patient_signup_view_model.dart';
import 'package:app/ui/features/patients/view_models/patients_view_model.dart';
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
        ChangeNotifierProvider(create: (_) => ActivePatientNotifier()),
        Provider<PatientAccessRemote>(
          create: (_) => SupabasePatientAccessRemote(),
        ),
        ProxyProvider2<AuthService, AppDatabase, AuthRepository>(
          update: (_, authService, db, _) => AuthRepository(
            authService: authService,
            db: db,
          ),
        ),
        ProxyProvider3<AppDatabase, AuthRepository, ActivePatientNotifier,
            SyncEngine>(
          update: (_, db, auth, activePatient, _) => SyncEngine(
            db: db,
            supabase: Supabase.instance.client,
            currentAuthUserId: () => auth.currentSession?.user.id,
            onAccessChanged: activePatient.markChanged,
          ),
        ),
        ProxyProvider2<SyncEngine, ConnectivityService, SyncCoordinator>(
          update: (_, engine, connectivity, _) => SyncCoordinator(
            engine: engine,
            isOnline: connectivity.isOnline,
          ),
        ),
        ProxyProvider4<AppDatabase, SyncCoordinator, PatientAccessRemote,
            ActivePatientNotifier, PatientRepository>(
          update: (_, db, coordinator, remote, activePatient, _) =>
              PatientRepository(
            db: db,
            onWrite: coordinator.onDriftWrite,
            remote: remote,
            activePatientNotifier: activePatient,
          ),
        ),
        ProxyProvider5<AppDatabase, PatientAccessRemote, AuthRepository,
            ActivePatientNotifier, SyncCoordinator, SharingRepository>(
          update: (_, db, remote, auth, activePatient, coordinator, _) =>
              SharingRepository(
            db: db,
            remote: remote,
            currentAuthUserId: () => auth.currentSession?.user.id,
            activePatientNotifier: activePatient,
            requestSync: coordinator.run,
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
        ProxyProvider<AppDatabase, MedicationsRepository>(
          update: (_, db, _) => MedicationsRepository(db: db),
        ),
        ProxyProvider4<AppDatabase, PatientRepository, AuthRepository,
            SyncCoordinator, PatientMedicationScheduleRepository>(
          update: (_, db, patients, auth, coordinator, _) =>
              PatientMedicationScheduleRepository(
            db: db,
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
            patientRepository: context.read<PatientRepository>(),
            syncCoordinator: context.read<SyncCoordinator>(),
            sharingRepository: context.read<SharingRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PatientsViewModel(
            authRepository: context.read<AuthRepository>(),
            patientRepository: context.read<PatientRepository>(),
            activePatientNotifier: context.read<ActivePatientNotifier>(),
            sharingRepository: context.read<SharingRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(
            authRepository: context.read<AuthRepository>(),
            patientRepository: context.read<PatientRepository>(),
            vitalsRepository: context.read<VitalsRepository>(),
            medicationsRepository: context.read<MedicationsRepository>(),
            scheduleRepository:
                context.read<PatientMedicationScheduleRepository>(),
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
        ChangeNotifierProxyProvider<MedicationsRepository,
            MedicationsViewModel>(
          create: (context) => MedicationsViewModel(
            medicationsRepository: context.read<MedicationsRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ??
              MedicationsViewModel(medicationsRepository: repository),
        ),
        ChangeNotifierProxyProvider3<VitalsRepository, MedicationsRepository,
            PatientMedicationScheduleRepository, JournalViewModel>(
          create: (context) => JournalViewModel(
            vitalsRepository: context.read<VitalsRepository>(),
            medicationsRepository: context.read<MedicationsRepository>(),
            scheduleRepository:
                context.read<PatientMedicationScheduleRepository>(),
          ),
          update: (_, vitals, medications, schedule, previous) =>
              previous ??
              JournalViewModel(
                vitalsRepository: vitals,
                medicationsRepository: medications,
                scheduleRepository: schedule,
              ),
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
