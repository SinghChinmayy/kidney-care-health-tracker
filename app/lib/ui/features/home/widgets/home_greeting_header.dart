import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({
    super.key,
    this.onOpenProfile,
  });

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingSm,
        AppTheme.spacingXs,
        AppTheme.spacingXs,
        0,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onOpenProfile,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.logWeight.withValues(alpha: 0.25),
              foregroundColor: AppTheme.ink,
              child: Text(
                viewModel.patientInitials,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${viewModel.greetingName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Welcome back!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _showComingSoon(context),
            icon: const Icon(Icons.notifications_outlined),
            color: AppTheme.ink,
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showModalBottomSheet<void>(
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
              AppTheme.spacingMd,
              AppTheme.spacingSm,
              AppTheme.spacingMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Coming soon',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.muted,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: AppTheme.secondaryButtonStyle(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
