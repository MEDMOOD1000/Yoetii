import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'day_dial.dart';
import 'plan_editor.dart';
import 'yoeti_plan.dart';

class TodayPlanTab extends StatefulWidget {
  const TodayPlanTab({super.key});
  @override
  State<TodayPlanTab> createState() => _TodayPlanTabState();
}

class _TodayPlanTabState extends State<TodayPlanTab> {
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
  Widget build(BuildContext context) =>
      DayPlanView(date: DateTime.now(), today: true);
}

class DayPlanView extends StatelessWidget {
  const DayPlanView({super.key, required this.date, this.today = false});
  final DateTime date;
  final bool today;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: YoetiPlan.instance,
      builder: (context, _) {
        final blocks = YoetiPlan.instance.forDate(date);
        final total = blocks.fold<int>(0, (n, b) => n + b.end - b.start);
        final taskLabel = blocks.isEmpty
            ? 'Add task'
            : blocks.length == 1
            ? 'Edit task'
            : 'Edit tasks';
        return Scaffold(
          appBar: today
              ? null
              : AppBar(
                  title: Text(
                    DateFormat('EEEE').format(date),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
          body: SafeArea(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 130),
                  children: [
                    Text(
                      today ? 'Today' : DateFormat('EEEE').format(date),
                      style: text.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('EEEE, MMMM d').format(date),
                      style: text.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.autorenew_rounded,
                                color: scheme.primary,
                                size: 19,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  today ? 'TODAY · 24 HOURS' : 'REPEATS WEEKLY',
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelMedium?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              Text(
                                (total / 60).toStringAsFixed(1) + 'h planned',
                                style: text.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, c) => Center(
                              child: DayDial(
                                size: (c.maxWidth - 8).clamp(220.0, 340.0),
                                blocks: blocks,
                                centerLabel: today ? 'TODAY' : '24 HOURS',
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _Timeline(date: date, blocks: blocks),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Day at a glance',
                            overflow: TextOverflow.ellipsis,
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          blocks.length.toString() +
                              (blocks.length == 1 ? ' task' : ' tasks'),
                          style: text.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (blocks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.edit_calendar_rounded,
                              size: 36,
                              color: scheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A clear day, ready to plan.',
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add a task to mark its place on the 24-hour wheel.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final block in blocks)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _BlockTile(date: date, block: block),
                        ),
                    const SizedBox(height: 20),
                    Text(
                      'Hours by type',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CategorySummary(blocks: blocks, total: total),
                  ],
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FilledButton.icon(
                    onPressed: () => _manageTasks(context, date, blocks),
                    icon: Icon(
                      blocks.isEmpty ? Icons.add_rounded : Icons.edit_rounded,
                    ),
                    label: Text(
                      taskLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 54),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _manageTasks(
  BuildContext context,
  DateTime date,
  List<PlanBlock> blocks,
) async {
  if (blocks.length <= 1) {
    await openPlanEditor(context, date, block: blocks.firstOrNull);
    return;
  }
  final selected = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit tasks',
              style: Theme.of(
                sheetContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final b in blocks)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: planCategoryColor(
                          sheetContext,
                          b.category,
                        ),
                        radius: 8,
                      ),
                      title: Text(b.title),
                      subtitle: Text(
                        planTime(b.start) + ' – ' + planTime(b.end),
                      ),
                      onTap: () => Navigator.of(sheetContext).pop(b),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(sheetContext).pop('add'),
                icon: const Icon(Icons.add),
                label: const Text('Add another task'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (context.mounted && selected != null)
    await openPlanEditor(
      context,
      date,
      block: selected is PlanBlock ? selected : null,
    );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.date, required this.blocks});
  final DateTime date;
  final List<PlanBlock> blocks;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Text('00:00', style: Theme.of(context).textTheme.labelSmall),
            const Spacer(),
            Text('24:00', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 7),
        LayoutBuilder(
          builder: (context, c) => GestureDetector(
            onTapDown: (d) {
              final minute =
                  ((d.localPosition.dx / c.maxWidth * 96).floor().clamp(
                    0,
                    95,
                  )) *
                  15;
              final selected = blocks
                  .where((b) => minute >= b.start && minute < b.end)
                  .firstOrNull;
              openPlanEditor(
                context,
                date,
                block: selected,
                suggestedStart: minute.clamp(0, 1380),
              );
            },
            child: SizedBox(
              height: 48,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  for (var hour = 6; hour < 24; hour += 6)
                    Positioned(
                      left: c.maxWidth * hour / 24,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 1, color: scheme.outlineVariant),
                    ),
                  for (final b in blocks)
                    Positioned(
                      left: c.maxWidth * b.start / 1440,
                      width: (c.maxWidth * (b.end - b.start) / 1440).clamp(
                        3.0,
                        c.maxWidth,
                      ),
                      top: 3,
                      bottom: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: planCategoryColor(context, b.category),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  if (DateUtils.isSameDay(date, DateTime.now()))
                    Positioned(
                      left:
                          (c.maxWidth *
                                  (DateTime.now().hour * 60 +
                                      DateTime.now().minute) /
                                  1440)
                              .clamp(0.0, c.maxWidth - 2),
                      top: -2,
                      bottom: -2,
                      child: Container(width: 2, color: scheme.error),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final h in ['00', '06', '12', '18', '24'])
              Text(
                h,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tap an empty time to add; tap a block to edit.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({required this.date, required this.block});
  final DateTime date;
  final PlanBlock block;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = planCategoryColor(context, block.category);
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openPlanEditor(context, date, block: block),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      block.category +
                          ' · ' +
                          planTime(block.start) +
                          ' – ' +
                          planTime(block.end),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                ((block.end - block.start) / 60).toStringAsFixed(1) + 'h',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySummary extends StatelessWidget {
  const _CategorySummary({required this.blocks, required this.total});
  final List<PlanBlock> blocks;
  final int total;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (total / 60).toStringAsFixed(1) + ' hours planned',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          for (final category in planCategories) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: planCategoryColor(context, category),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  (blocks
                                  .where((b) => b.category == category)
                                  .fold<int>(0, (n, b) => n + b.end - b.start) /
                              60)
                          .toStringAsFixed(1) +
                      'h',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: total == 0
                  ? 0
                  : blocks
                            .where((b) => b.category == category)
                            .fold<int>(0, (n, b) => n + b.end - b.start) /
                        total,
              color: planCategoryColor(context, category),
              backgroundColor: scheme.surfaceContainerHighest,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
