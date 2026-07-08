import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/home/widgets/home_date_header.dart';
import 'package:app/ui/features/vitals/views/blood_glucose_view.dart';
import 'package:app/ui/features/vitals/views/blood_pressure_view.dart';
import 'package:app/ui/features/vitals/views/vitals_hub_view.dart';
import 'package:app/ui/features/vitals/views/weight_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _homeContentMaxWidth = 600;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeDateHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingSm,
                    AppTheme.spacingSm,
                    AppTheme.spacingSm,
                    80,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _homeContentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppOptionCard(
                              title: 'Blood pressure',
                              description:
                                  viewModel.bloodPressureForSelectedDate
                                          ?.displayValue ??
                                      'No readings yet',
                              icon: Icons.monitor_heart_outlined,
                              titleStyle:
                                  Theme.of(context).textTheme.titleMedium,
                              onTap: () =>
                                  _open(context, const BloodPressureView()),
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            AppOptionCard(
                              title: 'Blood glucose',
                              description:
                                  viewModel.bloodGlucoseForSelectedDate
                                          ?.displayValue ??
                                      'No readings yet',
                              icon: Icons.water_drop_outlined,
                              titleStyle:
                                  Theme.of(context).textTheme.titleMedium,
                              onTap: () =>
                                  _open(context, const BloodGlucoseView()),
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            AppOptionCard(
                              title: 'Weight',
                              description:
                                  viewModel.weightForSelectedDate
                                          ?.displayValue ??
                                      'No readings yet',
                              icon: Icons.scale_outlined,
                              titleStyle:
                                  Theme.of(context).textTheme.titleMedium,
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
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, Widget page) {
    final homeViewModel = context.read<HomeViewModel>();
    return Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page))
        .then((_) => homeViewModel.refresh());
  }
}
