import 'package:app/ui/core/widgets/app_components.dart';
import 'package:app/ui/features/vitals/view_models/weight_view_model.dart';
import 'package:app/ui/features/vitals/views/weight_history_tab.dart';
import 'package:app/ui/features/vitals/views/weight_track_tab.dart';
import 'package:app/ui/features/vitals/widgets/vital_section_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeightView extends StatefulWidget {
  const WeightView({super.key});

  @override
  State<WeightView> createState() => _WeightViewState();
}

class _WeightViewState extends State<WeightView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WeightViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const AppScreenAppBar(title: 'Weight'),
        body: const Column(
          children: [
            VitalSectionTabBar(tabs: ['Track', 'History']),
            Expanded(
              child: TabBarView(
                children: [
                  WeightTrackTab(),
                  WeightHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
