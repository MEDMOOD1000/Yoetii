import 'package:flutter/material.dart';
import 'day_dial.dart';
import 'yoeti_plan.dart';

Future<void> openPlanEditor(
  BuildContext context,
  DateTime date, {
  PlanBlock? block,
  int? suggestedStart,
}) async {
  await YoetiPlan.instance.load();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) =>
        _PlanEditor(date: date, block: block, suggestedStart: suggestedStart),
  );
}

class _PlanEditor extends StatefulWidget {
  const _PlanEditor({required this.date, this.block, this.suggestedStart});
  final DateTime date;
  final PlanBlock? block;
  final int? suggestedStart;
  @override
  State<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<_PlanEditor> {
  late final TextEditingController _title = TextEditingController(
    text: widget.block?.title ?? '',
  );
  late String _category = widget.block?.category ?? planCategories.first;
  late int _start = widget.block?.start ?? (widget.suggestedStart ?? 540);
  late int _end =
      widget.block?.end ??
      ((widget.suggestedStart ?? 540) + 60).clamp(15, 1440);
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final current = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (current ~/ 60) % 24, minute: current % 60),
      helpText: start ? 'START TIME' : 'END TIME',
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (picked == null) return;
    final value = picked.hour * 60 + picked.minute;
    setState(() {
      if (start) {
        _start = value.clamp(0, _end - 1);
      } else {
        _end = (value == 0 ? 1440 : value).clamp(_start + 1, 1440);
      }
      _error = null;
    });
  }

  Future<void> _apply() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Name your task.');
      return;
    }
    if (YoetiPlan.instance.overlaps(
      widget.date,
      _start,
      _end,
      exceptId: widget.block?.id,
    )) {
      setState(() => _error = 'This time overlaps another task.');
      return;
    }
    final block = PlanBlock(
      id: widget.block?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      category: _category,
      start: _start,
      end: _end,
    );
    await YoetiPlan.instance.put(widget.date, block);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.block == null ? 'Plan a task' : 'Edit task',
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.block != null)
                    IconButton(
                      tooltip: 'Delete task',
                      color: scheme.error,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await YoetiPlan.instance.remove(
                          widget.date,
                          widget.block!.id,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                children: [
                  Text(
                    'SET YOUR TASK TIME',
                    style: text.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Drag the two handles to set your task time, start and end.',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final size = (c.maxWidth - 12).clamp(220.0, 340.0);
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: .82, end: 1),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: DayDial(
                            size: size,
                            blocks: YoetiPlan.instance
                                .forDate(widget.date)
                                .where((b) => b.id != widget.block?.id)
                                .toList(),
                            start: _start,
                            end: _end,
                            onRangeChanged: (start, end) => setState(() {
                              _start = start;
                              _end = end;
                              _error = null;
                            }),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pick(true),
                          icon: const Icon(Icons.schedule),
                          label: Text('Start  ' + planTime(_start)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pick(false),
                          icon: const Icon(Icons.schedule),
                          label: Text('End  ' + planTime(_end)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Task name',
                      hintText: 'What will you do?',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'TYPE',
                    style: text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final category in planCategories)
                        ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          avatar: CircleAvatar(
                            radius: 5,
                            backgroundColor: planCategoryColor(
                              context,
                              category,
                            ),
                          ),
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Repeats every ' + _weekday(widget.date),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                          side: BorderSide(color: scheme.error),
                          minimumSize: const Size(0, 54),
                        ),
                        child: const Text(
                          'Discard',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _apply,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 54),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _weekday(DateTime date) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][date.weekday - 1];
