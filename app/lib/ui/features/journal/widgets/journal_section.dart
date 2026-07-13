import 'package:app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class JournalSection extends StatelessWidget {
  const JournalSection({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.muted,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Container(
          decoration: AppTheme.homeCardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class JournalDetailRow extends StatelessWidget {
  const JournalDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingSm,
        AppTheme.spacingSm,
        AppTheme.spacingSm,
        isLast ? AppTheme.spacingSm : AppTheme.spacingSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: AppTheme.muted),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppTheme.muted.withValues(alpha: 0.55),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      child: content,
    );
  }
}

class JournalDivider extends StatelessWidget {
  const JournalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppTheme.spacingSm + 22 + AppTheme.spacingSm,
      color: AppTheme.muted.withValues(alpha: 0.15),
    );
  }
}
