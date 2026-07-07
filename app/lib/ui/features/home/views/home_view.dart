import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/vitals/views/blood_glucose_view.dart';
import 'package:app/ui/features/vitals/views/blood_pressure_view.dart';
import 'package:app/ui/features/vitals/views/vitals_hub_view.dart';
import 'package:app/ui/features/vitals/views/weight_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppScreenAppBar(
        title: 'Home',
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => viewModel.signOut(),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => viewModel.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          children: [
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Your latest vitals at a glance.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            AppOptionCard(
              title: 'Blood pressure',
              description:
                  viewModel.latestBloodPressure?.displayValue ?? 'No readings yet',
              icon: Icons.monitor_heart_outlined,
              titleStyle: Theme.of(context).textTheme.titleMedium,
              onTap: () => _open(context, const BloodPressureView()),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            AppOptionCard(
              title: 'Blood glucose',
              description:
                  viewModel.latestBloodGlucose?.displayValue ?? 'No readings yet',
              icon: Icons.water_drop_outlined,
              titleStyle: Theme.of(context).textTheme.titleMedium,
              onTap: () => _open(context, const BloodGlucoseView()),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            AppOptionCard(
              title: 'Weight',
              description:
                  viewModel.latestWeight?.displayValue ?? 'No readings yet',
              icon: Icons.scale_outlined,
              titleStyle: Theme.of(context).textTheme.titleMedium,
              onTap: () => _open(context, const WeightView()),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const VitalsHubView(),
                  ),
                );
              },
              style: AppTheme.secondaryButtonStyle(),
              child: const Text('View all vitals'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, Widget page) {
    final homeViewModel = context.read<HomeViewModel>();
    return Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page))
        .then((_) => homeViewModel.refresh());
  }
}
