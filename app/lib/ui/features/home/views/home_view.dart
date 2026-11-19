import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/home/widgets/home_greeting_header.dart';
import 'package:app/ui/features/home/widgets/home_vital_sparkline_tiles.dart';
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

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    this.onOpenProfile,
  });

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return ColoredBox(
      color: AppTheme.bpBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: _HomeWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeGreetingHeader(onOpenProfile: onOpenProfile),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppTheme.cardBorder,
                  ),
                  const HomeWeekStrip(),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppTheme.cardBorder,
                  ),
                ],
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
                  AppTheme.spacingMd,
                ),
                children: [
                  _HomeWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WeightGainCard(
                          snapshot: viewModel.weightGainForSelectedDate,
                          onTap: () => _openHistory(
                            context,
                            const WeightView(),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        SizedBox(
                          height: 148,
                          child: Row(
                            children: [
                              Expanded(
                                child: BloodGlucoseWidget(
                                  chartPoints: viewModel
                                      .bloodGlucoseChartForSelectedDate,
                                  onTap: () => _openHistory(
                                    context,
                                    const BloodGlucoseView(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: BloodPressureWidget(
                                  chartPoints: viewModel
                                      .bloodPressureChartForSelectedDate,
                                  onTap: () => _openHistory(
                                    context,
                                    const BloodPressureView(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 0.5,
                            child: SizedBox(
                              height: 108,
                              child: HomeVitalTile(
                                title: 'Water intake',
                                value: viewModel
                                    .fluidIntakeTotalMlForSelectedDate
                                    .toStringAsFixed(0),
                                unit: '/ ${viewModel.dailyWaterGoalMl} ml',
                                icon: Icons.local_drink_outlined,
                                accentColor: AppTheme.logFluidIntake,
                                isLogged: viewModel
                                        .fluidIntakeTotalMlForSelectedDate >
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
}

class _HomeWidth extends StatelessWidget {
  const _HomeWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _homeContentMaxWidth),
        child: child,
      ),
    );
  }
}
