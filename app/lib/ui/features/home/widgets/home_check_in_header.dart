import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class HomeCheckInHeader extends StatelessWidget {
  const HomeCheckInHeader({
    super.key,
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Daily check-in',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.logWeight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$completed/$total',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ),
      ],
    );
  }
}
