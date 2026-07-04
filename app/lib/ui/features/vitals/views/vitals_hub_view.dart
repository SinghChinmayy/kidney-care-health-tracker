import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/vitals/views/blood_glucose_view.dart';
import 'package:app/ui/features/vitals/views/blood_pressure_view.dart';
import 'package:app/ui/features/vitals/views/weight_view.dart';
import 'package:flutter/material.dart';

class VitalsHubView extends StatelessWidget {
  const VitalsHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppScreenAppBar(title: 'Vitals'),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        children: [
          Text(
            'Track your readings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Blood pressure, glucose, and weight from your patient profile.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          AppOptionCard(
            title: 'Blood pressure',
            description: 'Systolic/diastolic and heart rate',
            icon: Icons.monitor_heart_outlined,
            titleStyle: Theme.of(context).textTheme.titleMedium,
            onTap: () => _open(context, const BloodPressureView()),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          AppOptionCard(
            title: 'Blood glucose',
            description: 'Stored in mg/dL',
            icon: Icons.water_drop_outlined,
            titleStyle: Theme.of(context).textTheme.titleMedium,
            onTap: () => _open(context, const BloodGlucoseView()),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          AppOptionCard(
            title: 'Weight',
            description: 'Stored in kg',
            icon: Icons.scale_outlined,
            titleStyle: Theme.of(context).textTheme.titleMedium,
            onTap: () => _open(context, const WeightView()),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}
