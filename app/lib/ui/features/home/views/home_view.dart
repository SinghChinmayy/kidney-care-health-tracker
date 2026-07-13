import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/home/widgets/blood_glucose_card.dart';
import 'package:app/ui/features/home/widgets/blood_pressure_card.dart';
import 'package:app/ui/features/home/widgets/blood_pressure_widget.dart';
import 'package:app/ui/features/home/widgets/home_greeting_header.dart';
import 'package:app/ui/features/home/widgets/home_vital_tile.dart';
import 'package:app/ui/features/home/widgets/home_week_strip.dart';
import 'package:app/ui/features/home/widgets/weight_gain_card.dart';
import 'package:app/ui/features/medications/views/medications_view.dart';
import 'package:app/ui/features/vitals/views/blood_glucose_view.dart';
import 'package:app/ui/features/vitals/views/blood_pressure_view.dart';
import 'package:app/ui/features/vitals/views/fluid_intake_view.dart';
import 'package:app/ui/features/vitals/views/weight_view.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_menu_sheet.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_sheets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _homeContentMaxWidth = 600;

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

    return ColoredBox(
      color: AppTheme.bpBackground,
      child: Column(
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
                AppTheme.spacingMd,
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
                        // Water intake: 2×2 (half-width), above weight gain
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
                        const SizedBox(height: AppTheme.spacingSm),
                        // Weight gain: 4×2 (full width)
                        WeightGainCard(
                          snapshot: viewModel.weightGainForSelectedDate,
                          chart: viewModel.weightGainChartForSelectedDate,
                          onTap: () => _openHistory(
                            context,
                            const WeightView(),
                          ),
                        ),
                        // TODO: re-enable large cards when ready
                        // BloodGlucoseCard(
                        //   reading: viewModel.bloodGlucoseForSelectedDate,
                        //   chartPoints:
                        //       viewModel.bloodGlucoseChartForSelectedDate,
                        //   onTap: () => _openHistory(
                        //     context,
                        //     const BloodGlucoseView(),
                        //   ),
                        // ),
                        // const SizedBox(height: AppTheme.spacingSm),
                        // BloodPressureCard(
                        //   reading: viewModel.bloodPressureForSelectedDate,
                        //   chartPoints:
                        //       viewModel.bloodPressureChartForSelectedDate,
                        //   onTap: () => _openHistory(
                        //     context,
                        //     const BloodPressureView(),
                        //   ),
                        // ),
                        const SizedBox(height: AppTheme.spacingSm),
                        // Compact side-by-side widget tiles
                        SizedBox(
                          height: 148,
                          child: Row(
                            children: [
                              Expanded(
                                child: BloodGlucoseWidget(
                                  chartPoints:
                                      viewModel.bloodGlucoseChartForSelectedDate,
                                  onTap: () => _openHistory(
                                    context,
                                    const BloodGlucoseView(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: BloodPressureWidget(
                                  chartPoints:
                                      viewModel.bloodPressureChartForSelectedDate,
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
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openHistory(
                              context,
                              const MedicationsView(),
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardCornerRadius,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacingSm),
                              decoration: AppTheme.homeCardDecoration(),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceMuted,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.medication_outlined,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingSm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Medications',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Browse names, composition & info',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.muted,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppTheme.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
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
