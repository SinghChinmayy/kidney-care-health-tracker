import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/ui/features/auth/views/login_view.dart';
import 'package:app/ui/features/shell/views/app_shell_view.dart';
import 'package:app/ui/features/sync/views/initial_sync_gate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Routes between [LoginView] and the signed-in app based on auth session validity.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();

    return StreamBuilder<AuthState>(
      stream: authRepository.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.hasData
            ? snapshot.data!.session
            : authRepository.currentSession;

        if (session != null) {
          return InitialSyncGate(
            key: ValueKey(session.user.id),
            child: const AppShellView(),
          );
        }

        return const LoginView();
      },
    );
  }
}
