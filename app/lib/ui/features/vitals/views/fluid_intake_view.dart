import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/vitals/view_models/fluid_intake_view_model.dart';
import 'package:app/ui/features/vitals/views/fluid_intake_history_tab.dart';
import 'package:app/ui/features/vitals/views/fluid_intake_track_tab.dart';
import 'package:app/ui/features/vitals/widgets/vital_section_tab_bar.dart';
import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FluidIntakeView extends StatefulWidget {
  const FluidIntakeView({super.key});

  @override
  State<FluidIntakeView> createState() => _FluidIntakeViewState();
}

class _FluidIntakeViewState extends State<FluidIntakeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FluidIntakeViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const AppScreenAppBar(title: 'Water intake'),
        body: const Column(
          children: [
            VitalSectionTabBar(
              tabs: ['Track', 'History'],
              accentColor: AppTheme.logFluidIntake,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  FluidIntakeTrackTab(),
                  FluidIntakeHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
