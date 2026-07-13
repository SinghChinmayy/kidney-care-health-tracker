import 'package:app/domain/models/blood_pressure_reading.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/home/widgets/blood_glucose_card.dart';
import 'package:app/ui/features/home/widgets/home_check_in_header.dart';
import 'package:app/ui/features/home/widgets/home_greeting_header.dart';
import 'package:app/ui/features/home/widgets/home_vital_tile.dart';
import 'package:app/ui/features/home/widgets/home_week_strip.dart';
import 'package:app/ui/features/home/widgets/weight_gain_card.dart';
import 'package:app/ui/features/vitals/views/blood_glucose_view.dart';
import 'package:app/ui/features/vitals/views/blood_pressure_view.dart';
import 'package:app/ui/features/vitals/views/fluid_intake_view.dart';
import 'package:app/ui/features/vitals/views/weight_view.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_menu_sheet.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_sheets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _homeContentMaxWidth = 600;
const double _vitalGridGap = 12;

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.onOpenProfile,
  });

  final VoidCallback? onOpenProfile;

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
        SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _homeContentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeGreetingHeader(onOpenProfile: widget.onOpenProfile),
                  const HomeWeekStrip(),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingSm,
                AppTheme.spacingXs,
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
                          snapshot: viewModel.weightGainForSelectedDate,
                          chart: viewModel.weightGainChartForSelectedDate,
                          onTap: () => _openHistory(
                            context,
                            const WeightView(),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        BloodGlucoseCard(
                          reading: viewModel.bloodGlucoseForSelectedDate,
                          chartPoints:
                              viewModel.bloodGlucoseChartForSelectedDate,
                          onTap: () => _openHistory(
                            context,
                            const BloodGlucoseView(),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        HomeCheckInHeader(
                          completed: viewModel.checkInCompletedCount,
                          total: HomeViewModel.checkInTotal,
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: _vitalGridGap,
                          crossAxisSpacing: _vitalGridGap,
                          childAspectRatio: 1.15,
                          children: [
                            HomeVitalTile(
                              title: 'Blood pressure',
                              value: viewModel.bloodPressureForSelectedDate ==
                                      null
                                  ? 'No readings yet'
                                  : _bloodPressureValue(
                                      viewModel.bloodPressureForSelectedDate!,
                                    ),
                              unit: viewModel.bloodPressureForSelectedDate ==
                                      null
                                  ? null
                                  : (viewModel.bloodPressureForSelectedDate!
                                                  .systolic !=
                                              null &&
                                          viewModel.bloodPressureForSelectedDate!
                                                  .diastolic !=
                                              null
                                      ? 'mmHg'
                                      : 'bpm'),
                              icon: Icons.monitor_heart_outlined,
                              accentColor: AppTheme.logBloodPressure,
                              isLogged:
                                  viewModel.bloodPressureForSelectedDate !=
                                      null,
                              onTap: () => _openLog(
                                context,
                                VitalLogType.bloodPressure,
                              ),
                              onHistoryTap: () => _openHistory(
                                context,
                                const BloodPressureView(),
                              ),
                            ),
                            HomeVitalTile(
                              title: 'Water intake',
                              value: viewModel
                                  .fluidIntakeTotalMlForSelectedDate
                                  .toStringAsFixed(0),
                              unit: '/ ${viewModel.dailyWaterGoalMl} ml',
                              icon: Icons.local_drink_outlined,
                              accentColor: AppTheme.logFluidIntake,
                              isLogged:
                                  viewModel.fluidIntakeTotalMlForSelectedDate >
                                      0,
                              progress: viewModel.fluidIntakeProgress,
                              progressOverGoal: viewModel.isFluidOverGoal,
                              onTap: () => _openLog(
                                context,
                                VitalLogType.fluidIntake,
                              ),
                              onHistoryTap: () => _openHistory(
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
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openLog(BuildContext context, VitalLogType type) {
    final homeViewModel = context.read<HomeViewModel>();
    return showVitalLogSheet(
      context,
      type,
      initialRecordedAt: homeViewModel.logRecordedAt,
      onSaved: homeViewModel.refresh,
    );
  }

  Future<void> _openHistory(BuildContext context, Widget page) {
    final homeViewModel = context.read<HomeViewModel>();
    return Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page))
        .then((_) => homeViewModel.refresh());
  }

  String _bloodPressureValue(BloodPressureReading reading) {
    if (reading.systolic != null && reading.diastolic != null) {
      return '${reading.systolic}/${reading.diastolic}';
    }
    if (reading.heartRateBpm != null) {
      return '${reading.heartRateBpm}';
    }
    return '—';
  }
}
