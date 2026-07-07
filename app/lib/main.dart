import 'package:app/app.dart';
import 'package:app/core/supabase_config.dart';
import 'package:app/data/local/app_database.dart';
import 'package:app/data/local/database_holder.dart';
import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configError = SupabaseConfig.validationError;
  if (configError != null) {
    runApp(ConfigErrorApp(message: configError));
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  appDatabase = AppDatabase();
  runApp(const KidneyCareApp());
}

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacingLg),
                Icon(Icons.settings_outlined, size: 48, color: AppTheme.ink),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Supabase config missing',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppTheme.spacingMd),
                SelectableText(
                  'flutter run --dart-define-from-file=dart_defines/dev.json',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
