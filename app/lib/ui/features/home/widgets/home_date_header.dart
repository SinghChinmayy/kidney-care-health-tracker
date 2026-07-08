import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _homeContentMaxWidth = 600;

class HomeDateHeader extends StatelessWidget {
  const HomeDateHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final dateLabel = viewModel.selectedDateLabel;

    return Material(
      color: AppTheme.logWeight,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _homeContentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXs,
                vertical: AppTheme.spacingXs,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous day',
                    onPressed: viewModel.selectPreviousDay,
                    icon: const Icon(Icons.chevron_left),
                    color: AppTheme.background,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => viewModel.pickDate(context),
                      borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingXs,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: AppTheme.background,
                            ),
                            const SizedBox(width: AppTheme.spacingXs),
                            Flexible(
                              child: Text(
                                dateLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppTheme.background,
                                      fontWeight: FontWeight.w600,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next day',
                    onPressed: viewModel.selectNextDay,
                    icon: const Icon(Icons.chevron_right),
                    color: AppTheme.background,
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: viewModel.signOut,
                    icon: const Icon(Icons.logout_outlined),
                    color: AppTheme.background,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
