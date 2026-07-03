import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient.dart';
import '../services/patient_repository.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'onboarding/onboarding_screen.dart';

/// Root routing widget: decides whether to show sign-in, onboarding, or the
/// signed-in app shell.
///
/// Per the sync plan (`planning/sync/v0/stage-1.md` §3.1 / §12.1): no local
/// writes are allowed before authentication, and every signed-in user has a
/// `patients` row (bootstrap trigger) that may still need onboarding
/// (`full_name IS NULL`) before the rest of the app is usable.
///
/// `Supabase.instance.client.auth.onAuthStateChange` also fires once on
/// startup with the session restored from local storage, so this widget
/// doubles as the "local auth" check — no separate local session store
/// needed.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final PatientRepository _patientRepository;
  Future<Patient>? _patientFuture;
  String? _patientFutureForUserId;

  @override
  void initState() {
    super.initState();
    _patientRepository = PatientRepository(Supabase.instance.client);
  }

  /// Only (re)fetches when the signed-in user actually changes, so events
  /// like token refresh don't flash the loading screen. Pass a userId to
  /// force a refetch for that user (e.g. after onboarding completes).
  Future<Patient> _patientFutureFor(String userId) {
    if (_patientFutureForUserId != userId || _patientFuture == null) {
      _patientFutureForUserId = userId;
      _patientFuture = _patientRepository.fetchCurrentPatient();
    }
    return _patientFuture!;
  }

  void _reloadPatient() {
    setState(() {
      _patientFuture = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session == null) {
          _patientFuture = null;
          _patientFutureForUserId = null;
          return const LoginScreen();
        }
        return FutureBuilder<Patient>(
          future: _patientFutureFor(session.user.id),
          builder: (context, patientSnapshot) {
            if (patientSnapshot.connectionState != ConnectionState.done) {
              return const _LoadingScreen();
            }
            if (patientSnapshot.hasError) {
              return _ErrorScreen(
                message: 'Could not load your profile: ${patientSnapshot.error}',
                onRetry: _reloadPatient,
              );
            }
            final patient = patientSnapshot.data!;
            if (!patient.isProfileComplete) {
              return OnboardingScreen(onComplete: _reloadPatient);
            }
            return HomeScreen(patient: patient);
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
