import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/home/views/home_view.dart';
import 'package:app/ui/features/profile/views/profile_view.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_menu_sheet.dart';
import 'package:app/ui/features/vitals/widgets/vital_log_sheets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppShellView extends StatefulWidget {
  const AppShellView({super.key});

  @override
  State<AppShellView> createState() => _AppShellViewState();
}

class _AppShellViewState extends State<AppShellView> {
  /// 0 = Home, 1 = Profile
  int _selectedIndex = 0;

  void _openProfile() {
    setState(() => _selectedIndex = 1);
  }

  Future<void> _openLogMenu() async {
    final viewModel = context.read<HomeViewModel>();
    final type = await showVitalLogMenuSheet(context);
    if (!mounted || type == null) {
      return;
    }
    await showVitalLogSheet(
      context,
      type,
      initialRecordedAt: viewModel.logRecordedAt,
      onSaved: viewModel.refresh,
    );
  }

  void _openNotifications() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bpBackground,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeView(onOpenProfile: _openProfile),
          const ProfileView(),
        ],
      ),
      bottomNavigationBar: _LightBottomNavBar(
        selectedIndex: _selectedIndex,
        onHomeTap: () => setState(() => _selectedIndex = 0),
        onLogTap: _openLogMenu,
        onNotificationsTap: _openNotifications,
        onProfileTap: () => setState(() => _selectedIndex = 1),
      ),
    );
  }
}

class _LightBottomNavBar extends StatelessWidget {
  const _LightBottomNavBar({
    required this.selectedIndex,
    required this.onHomeTap,
    required this.onLogTap,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  final int selectedIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onLogTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  static const _barColor = Color(0xFFFFFFFF);
  static const _activeFill = Color(0xFF4A3728);
  static const _inactiveIcon = Color(0xFF6B5E54);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.bpBackground,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: _barColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppTheme.cardBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: _HomeNavButton(
                      selected: selectedIndex == 0,
                      onTap: onHomeTap,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _CenterLogButton(onTap: onLogTap),
                  ),
                ),
                Expanded(
                  child: _NavIconButton(
                    selected: false,
                    onTap: onNotificationsTap,
                    activeFill: _activeFill,
                    child: Icon(
                      Icons.notifications_outlined,
                      size: 26,
                      color: _inactiveIcon,
                    ),
                  ),
                ),
                Expanded(
                  child: _NavIconButton(
                    selected: selectedIndex == 1,
                    onTap: onProfileTap,
                    activeFill: _activeFill,
                    child: Icon(
                      Icons.person_outline,
                      size: 26,
                      color: selectedIndex == 1
                          ? AppTheme.background
                          : _inactiveIcon,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeNavButton extends StatelessWidget {
  const _HomeNavButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  static const _fill = Color(0xFF4A3728);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _fill : _fill.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      elevation: selected ? 2 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            selected ? Icons.home_rounded : Icons.home_outlined,
            color: selected ? AppTheme.background : _fill,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.selected,
    required this.onTap,
    required this.activeFill,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Color activeFill;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? activeFill : Colors.transparent,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CenterLogButton extends StatelessWidget {
  const _CenterLogButton({required this.onTap});

  final VoidCallback onTap;

  static const _fill = Color(0xFF4A3728);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _fill,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            Icons.add,
            color: AppTheme.background,
            size: 30,
          ),
        ),
      ),
    );
  }
}
