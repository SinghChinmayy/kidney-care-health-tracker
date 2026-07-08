import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/vitals/view_models/blood_pressure_view_model.dart';
import 'package:app/ui/features/vitals/views/blood_pressure_history_tab.dart';
import 'package:app/ui/features/vitals/views/blood_pressure_track_tab.dart';
import 'package:app/ui/features/vitals/widgets/vital_section_tab_bar.dart';
import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BloodPressureView extends StatefulWidget {
  const BloodPressureView({super.key});

  @override
  State<BloodPressureView> createState() => _BloodPressureViewState();
}

class _BloodPressureViewState extends State<BloodPressureView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BloodPressureViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const AppScreenAppBar(title: 'Blood pressure'),
        body: const Column(
          children: [
            VitalSectionTabBar(
              tabs: ['Track', 'History'],
              accentColor: AppTheme.logBloodPressure,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  BloodPressureTrackTab(),
                  BloodPressureHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
