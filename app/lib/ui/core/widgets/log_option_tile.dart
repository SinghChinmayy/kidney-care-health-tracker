import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LogOptionTile extends StatelessWidget {
  const LogOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceMuted,
      borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingXs + 4,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.muted.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.background, size: 22),
              ),
              const SizedBox(width: AppTheme.spacingXs + 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
