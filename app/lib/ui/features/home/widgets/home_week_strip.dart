import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _shortWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Fixed Monday used as week-index origin (2000-01-03 was a Monday).
final _epochMonday = DateTime(2000, 1, 3);

/// Enough weeks for ~200 years either side of the epoch.
const _pageCount = 20000;

const _dayCircleSize = 34.0;

class HomeWeekStrip extends StatefulWidget {
  const HomeWeekStrip({super.key});

  @override
  State<HomeWeekStrip> createState() => _HomeWeekStripState();
}

class _HomeWeekStripState extends State<HomeWeekStrip> {
  late final PageController _pageController;
  DateTime? _lastSyncedWeekStart;
  bool _programmaticPageChange = false;

  @override
  void initState() {
    super.initState();
    final initialWeek = weekStartForLocalDate(DateTime.now());
    _pageController = PageController(
      initialPage: _pageForWeekStart(initialWeek),
    );
    _lastSyncedWeekStart = initialWeek;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _pageForWeekStart(DateTime weekStart) {
    return weekStart.difference(_epochMonday).inDays ~/ 7;
  }

  DateTime _weekStartForPage(int page) {
    return _epochMonday.add(Duration(days: page * 7));
  }

  Future<void> _jumpToWeek(DateTime weekStart, {bool animate = true}) async {
    if (!_pageController.hasClients) return;
    final page = _pageForWeekStart(weekStart);
    if (page < 0 || page >= _pageCount) return;

    final current = _pageController.page?.round();
    if (current == page) {
      _lastSyncedWeekStart = weekStart;
      return;
    }

    _programmaticPageChange = true;
    _lastSyncedWeekStart = weekStart;
    if (animate) {
      await _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _pageController.jumpToPage(page);
    }
    _programmaticPageChange = false;
  }

  void _onPageChanged(int page) {
    if (_programmaticPageChange) return;
    final weekStart = _weekStartForPage(page);
    _lastSyncedWeekStart = weekStart;
    context.read<HomeViewModel>().selectWeekStarting(weekStart);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final selected = viewModel.selectedDate;
    final today = viewModel.today;
    final weekStart = viewModel.visibleWeekStart;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      if (_lastSyncedWeekStart == weekStart) return;
      if (_programmaticPageChange) return;
      _jumpToWeek(weekStart, animate: _lastSyncedWeekStart != null);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingSm,
        AppTheme.spacingXs,
        AppTheme.spacingXs,
        AppTheme.spacingXs,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 72,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pageCount,
                itemBuilder: (context, page) {
                  final start = _weekStartForPage(page);
                  return Row(
                    children: List.generate(7, (i) {
                      final day = start.add(Duration(days: i));
                      final isFuture = day.isAfter(today);
                      return Expanded(
                        child: _DayChip(
                          weekdayLabel: _shortWeekdays[i],
                          dayNumber: '${day.day}',
                          isSelected: day == selected,
                          isToday: day == today,
                          enabled: !isFuture,
                          onTap: isFuture
                              ? null
                              : () => viewModel.selectDate(day),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
          IconButton(
            tooltip: 'Pick a date',
            onPressed: () async {
              await viewModel.pickDate(context);
              if (!mounted) return;
              await _jumpToWeek(viewModel.visibleWeekStart);
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
            color: AppTheme.ink,
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.weekdayLabel,
    required this.dayNumber,
    required this.isSelected,
    required this.isToday,
    required this.enabled,
    required this.onTap,
  });

  final String weekdayLabel;
  final String dayNumber;
  final bool isSelected;
  final bool isToday;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final weekdayColor = !enabled
        ? AppTheme.muted.withValues(alpha: 0.4)
        : isSelected
            ? AppTheme.ink
            : AppTheme.muted;

    final dayNumberColor = !enabled
        ? AppTheme.muted.withValues(alpha: 0.4)
        : isSelected
            ? AppTheme.cardSurface
            : AppTheme.ink;

    final circleFill = !enabled
        ? AppTheme.cardSurface.withValues(alpha: 0.5)
        : isSelected
            ? AppTheme.ink
            : AppTheme.cardSurface;

    final showTodayRing = isToday && !isSelected && enabled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_dayCircleSize),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekdayLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: weekdayColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: _dayCircleSize,
              height: _dayCircleSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleFill,
                border: showTodayRing
                    ? Border.all(color: AppTheme.logWeight, width: 2)
                    : (!isSelected && enabled
                        ? Border.all(color: AppTheme.cardBorder)
                        : null),
              ),
              child: Text(
                dayNumber,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: dayNumberColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
