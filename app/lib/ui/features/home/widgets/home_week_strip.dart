import 'package:app/theme/app_theme.dart';
import 'package:app/ui/features/home/view_models/home_view_model.dart';
import 'package:app/ui/features/vitals/utils/vital_formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _shortWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Earliest day available in the strip (inclusive).
final _stripFirstDate = DateTime(2000, 1, 1);

const _dayCircleSize = 34.0;

class HomeWeekStrip extends StatefulWidget {
  const HomeWeekStrip({super.key});

  @override
  State<HomeWeekStrip> createState() => _HomeWeekStripState();
}

class _HomeWeekStripState extends State<HomeWeekStrip> {
  final ScrollController _scrollController = ScrollController();
  double _itemWidth = 48;
  double _viewportWidth = 0;
  DateTime? _lastSyncedSelection;
  bool _programmaticScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _indexFor(DateTime date) {
    final day = localDateOnly(date);
    return day.difference(_stripFirstDate).inDays;
  }

  DateTime _dateForIndex(int index) {
    return _stripFirstDate.add(Duration(days: index));
  }

  int _itemCount(DateTime today) => _indexFor(today) + 1;

  double _offsetToCenter({
    required int index,
    required double viewportWidth,
    required DateTime today,
  }) {
    final raw = index * _itemWidth - (viewportWidth - _itemWidth) / 2;
    final maxScroll = (_itemCount(today) * _itemWidth) - viewportWidth;
    return raw.clamp(0.0, maxScroll < 0 ? 0.0 : maxScroll);
  }

  Future<void> _scrollToDate(
    DateTime date, {
    required double viewportWidth,
    required DateTime today,
    bool animate = true,
  }) async {
    if (!_scrollController.hasClients) return;
    final index = _indexFor(date);
    final target = _offsetToCenter(
      index: index,
      viewportWidth: viewportWidth,
      today: today,
    );
    _programmaticScroll = true;
    _lastSyncedSelection = localDateOnly(date);
    if (animate) {
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
    _programmaticScroll = false;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final selected = viewModel.selectedDate;
    final today = viewModel.today;

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _itemWidth = constraints.maxWidth / 7;
                  _viewportWidth = constraints.maxWidth;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || !_scrollController.hasClients) return;
                    // Center on selection when it changes via tap/picker,
                    // not while the user is freely scrolling the strip.
                    if (_lastSyncedSelection == selected) return;
                    if (_programmaticScroll) return;
                    _scrollToDate(
                      selected,
                      viewportWidth: constraints.maxWidth,
                      today: today,
                      animate: _lastSyncedSelection != null,
                    );
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: _DaySnapScrollPhysics(itemWidth: _itemWidth),
                    itemExtent: _itemWidth,
                    itemCount: _itemCount(today),
                    itemBuilder: (context, index) {
                      final day = _dateForIndex(index);
                      final isFuture = day.isAfter(today);
                      final isSelected = day == selected;
                      final isToday = day == today;
                      final isDialysis = viewModel.isDialysisDay(day);
                      return _DayChip(
                        weekdayLabel: _shortWeekdays[day.weekday - 1],
                        dayNumber: '${day.day}',
                        isSelected: isSelected,
                        isToday: isToday,
                        isDialysis: isDialysis,
                        enabled: !isFuture,
                        onTap: isFuture
                            ? null
                            : () => viewModel.selectDate(day),
                      );
                    },
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
              if (_viewportWidth <= 0) return;
              await _scrollToDate(
                viewModel.selectedDate,
                viewportWidth: _viewportWidth,
                today: viewModel.today,
                animate: true,
              );
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
            color: AppTheme.ink,
          ),
        ],
      ),
    );
  }
}

/// Snaps horizontal scroll to day-sized increments for smooth day-by-day feel.
class _DaySnapScrollPhysics extends ScrollPhysics {
  const _DaySnapScrollPhysics({
    required this.itemWidth,
    super.parent,
  });

  final double itemWidth;

  @override
  _DaySnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _DaySnapScrollPhysics(
      itemWidth: itemWidth,
      parent: buildParent(ancestor),
    );
  }

  double _snapTo(double offset) {
    if (itemWidth <= 0) return offset;
    return (offset / itemWidth).roundToDouble() * itemWidth;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final simulation = super.createBallisticSimulation(position, velocity);
    if (position.outOfRange) return simulation;

    final target = _snapTo(
      simulation == null
          ? position.pixels
          : simulation.x(double.infinity).clamp(
                position.minScrollExtent,
                position.maxScrollExtent,
              ),
    );

    if ((target - position.pixels).abs() < 0.5) {
      return simulation;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      velocity,
      tolerance: toleranceFor(position),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.weekdayLabel,
    required this.dayNumber,
    required this.isSelected,
    required this.isToday,
    required this.isDialysis,
    required this.enabled,
    required this.onTap,
  });

  final String weekdayLabel;
  final String dayNumber;
  final bool isSelected;
  final bool isToday;
  final bool isDialysis;
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
            const SizedBox(height: 2),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDialysis
                    ? (isSelected ? AppTheme.ink : AppTheme.logWeight)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
