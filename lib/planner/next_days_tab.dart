import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'day_dial.dart';
import 'today_plan_tab.dart';
import 'yoeti_plan.dart';

class NextDaysTab extends StatefulWidget {
  const NextDaysTab({super.key});
  @override
  State<NextDaysTab> createState() => _NextDaysTabState();
}

class _NextDaysTabState extends State<NextDaysTab> {
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    YoetiPlan.instance.load();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            Text(
              'Next days',
              style: text.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your week keeps moving. Tap a day to focus and plan.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            for (var offset = 1; offset <= 6; offset++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NextDayCard(
                  key: ValueKey(today.add(Duration(days: offset)).weekday),
                  date: today.add(Duration(days: offset)),
                  tomorrow: offset == 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NextDayCard extends StatefulWidget {
  const _NextDayCard({super.key, required this.date, required this.tomorrow});
  final DateTime date;
  final bool tomorrow;
  @override
  State<_NextDayCard> createState() => _NextDayCardState();
}

class _NextDayCardState extends State<_NextDayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.tomorrow ? 30 : 7),
  )..repeat();
  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _open() async {
    _spin.stop();
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => DayPlanView(date: widget.date),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: .88, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),
    );
    if (mounted) _spin.repeat();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: YoetiPlan.instance,
    builder: (context, _) {
      final scheme = Theme.of(context).colorScheme;
      final text = Theme.of(context).textTheme;
      final blocks = YoetiPlan.instance.forDate(widget.date);
      final total = blocks.fold<int>(0, (n, b) => n + b.end - b.start);
      return Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: _open,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tomorrow
                            ? 'TOMORROW'
                            : DateFormat(
                                'EEEE',
                              ).format(widget.date).toUpperCase(),
                        style: text.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DateFormat('MMM d').format(widget.date),
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        blocks.length.toString() +
                            (blocks.length == 1 ? ' task' : ' tasks'),
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        (total / 60).toStringAsFixed(1) + ' hours planned',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Icon(Icons.zoom_in_rounded, color: scheme.primary),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _spin,
                  builder: (_, _) => DayDial(
                    size: 176,
                    blocks: blocks,
                    rotation: _spin.value * 6.283185307179586,
                    centerLabel: widget.tomorrow
                        ? 'TOMORROW'
                        : DateFormat('EEE').format(widget.date).toUpperCase(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
