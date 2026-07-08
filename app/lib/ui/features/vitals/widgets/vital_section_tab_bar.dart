import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class VitalSectionTabBar extends StatelessWidget {
  const VitalSectionTabBar({
    super.key,
    required this.tabs,
    this.accentColor = AppTheme.logWeight,
  });

  final List<String> tabs;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      indicatorColor: accentColor,
      indicatorWeight: 3,
      labelColor: AppTheme.ink,
      unselectedLabelColor: AppTheme.muted,
      dividerColor: AppTheme.muted.withValues(alpha: 0.25),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
      tabs: tabs.map((label) => Tab(text: label.toUpperCase())).toList(),
    );
  }
}
