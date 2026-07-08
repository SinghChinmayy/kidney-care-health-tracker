import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _profileContentMaxWidth = 600;

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _profileContentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Account settings and sign out.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.read<AuthRepository>().signOut(),
                  style: AppTheme.secondaryButtonStyle(),
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
