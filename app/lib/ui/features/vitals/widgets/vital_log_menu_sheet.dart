import 'package:app/theme/app_theme.dart';
import 'package:app/ui/core/widgets/log_option_tile.dart';
import 'package:flutter/material.dart';

enum VitalLogType {
  bloodPressure,
  bloodGlucose,
  weight,
}

Future<VitalLogType?> showVitalLogMenuSheet(BuildContext context) {
  return showModalBottomSheet<VitalLogType>(
    context: context,
    backgroundColor: AppTheme.background,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.sheetTopRadius,
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingSm,
            AppTheme.spacingXs,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text('Log', style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: AppTheme.spacingSm),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppTheme.spacingXs,
                crossAxisSpacing: AppTheme.spacingXs,
                childAspectRatio: 2.5,
                children: [
                  LogOptionTile(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Blood pressure',
                    accentColor: AppTheme.logBloodPressure,
                    onTap: () => Navigator.of(sheetContext).pop(
                      VitalLogType.bloodPressure,
                    ),
                  ),
                  LogOptionTile(
                    icon: Icons.water_drop_outlined,
                    label: 'Blood glucose',
                    accentColor: AppTheme.logBloodGlucose,
                    onTap: () => Navigator.of(sheetContext).pop(
                      VitalLogType.bloodGlucose,
                    ),
                  ),
                  LogOptionTile(
                    icon: Icons.scale_outlined,
                    label: 'Weight',
                    accentColor: AppTheme.logWeight,
                    onTap: () => Navigator.of(sheetContext).pop(
                      VitalLogType.weight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
