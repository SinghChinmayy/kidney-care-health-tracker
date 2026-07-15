import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/home/views/home_view.dart';
import 'package:app/ui/features/journal/view_models/journal_view_model.dart';
import 'package:app/ui/features/journal/views/journal_view.dart';
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
  /// 0 = Home, 1 = Journal, 2 = Profile
  int _selectedIndex = 0;

  void _openProfile() {
    setState(() => _selectedIndex = 2);
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      context.read<JournalViewModel>().refresh();
    }
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
      onSaved: () {
        viewModel.refresh();
        context.read<JournalViewModel>().refresh();
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
          const JournalView(),
          const ProfileView(),
        ],
      ),
      bottomNavigationBar: _LightBottomNavBar(
        selectedIndex: _selectedIndex,
        onHomeTap: () => _selectTab(0),
        onJournalTap: () => _selectTab(1),
        onLogTap: _openLogMenu,
        onProfileTap: () => _selectTab(2),
      ),
    );
  }
}

class _LightBottomNavBar extends StatelessWidget {
  const _LightBottomNavBar({
    required this.selectedIndex,
    required this.onHomeTap,
    required this.onJournalTap,
    required this.onLogTap,
    required this.onProfileTap,
  });

  final int selectedIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onJournalTap;
  final VoidCallback onLogTap;
  final VoidCallback onProfileTap;

  static const _barColor = Color(0xFFFFFFFF);

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
                    child: _NavCircleButton(
                      selected: selectedIndex == 0,
                      onTap: onHomeTap,
                      selectedIcon: Icons.home_rounded,
                      unselectedIcon: Icons.home_outlined,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _NavCircleButton(
                      selected: selectedIndex == 1,
                      onTap: onJournalTap,
                      selectedIcon: Icons.menu_book_rounded,
                      unselectedIcon: Icons.menu_book_outlined,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _NavCircleButton(
                      // Log is an action, not a tab — always use active fill.
                      selected: true,
                      onTap: onLogTap,
                      selectedIcon: Icons.add,
                      unselectedIcon: Icons.add,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _NavCircleButton(
                      selected: selectedIndex == 2,
                      onTap: onProfileTap,
                      selectedIcon: Icons.person,
                      unselectedIcon: Icons.person_outline,
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

/// Shared circular nav control — same size and colors for every slot.
class _NavCircleButton extends StatelessWidget {
  const _NavCircleButton({
    required this.selected,
    required this.onTap,
    required this.selectedIcon,
    required this.unselectedIcon,
  });

  final bool selected;
  final VoidCallback onTap;
  final IconData selectedIcon;
  final IconData unselectedIcon;

  static const _fill = Color(0xFF4A3728);
  static const double _size = 56;

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
          width: _size,
          height: _size,
          child: Icon(
            selected ? selectedIcon : unselectedIcon,
            color: selected ? AppTheme.cardSurface : _fill,
            size: 30,
          ),
        ),
      ),
    );
  }
}
