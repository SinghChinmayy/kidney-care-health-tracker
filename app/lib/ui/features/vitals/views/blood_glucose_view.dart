import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/vitals/view_models/blood_glucose_view_model.dart';
import 'package:app/ui/features/vitals/views/blood_glucose_history_tab.dart';
import 'package:app/ui/features/vitals/views/blood_glucose_track_tab.dart';
import 'package:app/ui/features/vitals/widgets/vital_section_tab_bar.dart';
import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BloodGlucoseView extends StatefulWidget {
  const BloodGlucoseView({super.key});

  @override
  State<BloodGlucoseView> createState() => _BloodGlucoseViewState();
}

class _BloodGlucoseViewState extends State<BloodGlucoseView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BloodGlucoseViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const AppScreenAppBar(title: 'Blood glucose'),
        body: const Column(
          children: [
            VitalSectionTabBar(
              tabs: ['Track', 'History'],
              accentColor: AppTheme.logBloodGlucose,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  BloodGlucoseTrackTab(),
                  BloodGlucoseHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
