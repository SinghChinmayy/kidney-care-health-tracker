import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/patient.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Placeholder signed-in home screen — shown once auth + onboarding are
/// both satisfied. Vitals logging/history views land here in a later pass
/// once the local DB + sync engine (`planning/sync/v0/stage-1.md`) exist.
class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.patient, super.key});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kidney Care'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => AuthService(Supabase.instance.client).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome, ${patient.fullName}',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Vitals tracking is coming soon.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
