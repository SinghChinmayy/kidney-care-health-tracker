import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/home/widgets/home_date_header.dart';
import 'package:app/ui/features/home/widgets/home_vital_tile.dart';
import 'package:app/ui/features/home/widgets/weight_gain_card.dart';
import 'package:app/ui/features/vitals/views/blood_glucose_view.dart';
import 'package:app/ui/features/vitals/views/blood_pressure_view.dart';
import 'package:app/ui/features/vitals/views/fluid_intake_view.dart';
import 'package:app/ui/features/vitals/views/weight_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _homeContentMaxWidth = 600;
const double _vitalGridGap = AppTheme.spacingXs;

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
                            WeightGainCard(
                              weightGain: viewModel.weightGainForSelectedDate,
                              onTap: () => _open(context, const WeightView()),
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: _vitalGridGap,
                              crossAxisSpacing: _vitalGridGap,
                              childAspectRatio: 1.45,
                              children: [
                                HomeVitalTile(
                                  title: 'Blood pressure',
                                  value: viewModel
                                          .bloodPressureForSelectedDate
                                          ?.displayValue ??
                                      'No readings yet',
                                  icon: Icons.monitor_heart_outlined,
                                  onTap: () => _open(
                                    context,
                                    const BloodPressureView(),
                                  ),
                                ),
                                HomeVitalTile(
                                  title: 'Blood glucose',
                                  value: viewModel
                                          .bloodGlucoseForSelectedDate
                                          ?.displayValue ??
                                      'No readings yet',
                                  icon: Icons.water_drop_outlined,
                                  onTap: () => _open(
                                    context,
                                    const BloodGlucoseView(),
                                  ),
                                ),
                                HomeVitalTile(
                                  title: 'Weight',
                                  value: viewModel.weightForSelectedDate
                                          ?.displayValue ??
                                      'No readings yet',
                                  icon: Icons.scale_outlined,
                                  onTap: () =>
                                      _open(context, const WeightView()),
                                ),
                                HomeVitalTile(
                                  title: 'Water intake',
                                  value: viewModel
                                          .fluidIntakeForSelectedDateLabel ??
                                      'No intake logged',
                                  icon: Icons.local_drink_outlined,
                                  onTap: () => _open(
                                    context,
                                    const FluidIntakeView(),
                                  ),
                                ),
                              ],
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
