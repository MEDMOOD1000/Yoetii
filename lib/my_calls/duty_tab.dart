import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'roster.dart';
import 'store.dart';

class DutyTab extends StatefulWidget {
  const DutyTab({super.key});
  @override
  State<DutyTab> createState() => _DutyTabState();
}

class _DutyTabState extends State<DutyTab> {
  bool importing = false;
  String? error;
  String search = '';
  bool showPast = false;

  @override
  void initState() {
    super.initState();
    MyCallsStore.instance.load();
  }

  Future<void> _import() async {
    if (importing) return;
    setState(() {
      importing = true;
      error = null;
    });
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (picked == null) return;
      final file = picked;
      if ((await file.length() ?? 0) > 15 * 1024 * 1024)
        throw const FormatException('Maximum file size is 15 MB.');
      final bytes = await file.readAsBytes();
      final roster = RosterParser.fromWorkbook(bytes, file.name);
      await MyCallsStore.instance.setRoster(roster);
      if (mounted)
        setState(() {
          search = '';
          showPast = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          error = e is FormatException
              ? e.message
              : 'Could not open this workbook. Check its format and try again.';
        });
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: MyCallsStore.instance,
    builder: (context, _) {
      final store = MyCallsStore.instance;
      final roster = store.roster;
      final person = store.selectedEmployee;
      final scheme = Theme.of(context).colorScheme;
      final style = Theme.of(context).textTheme;
      final today = dayKey(DateTime.now());
      final days = roster?.days ?? <RosterDay>[];
      final work = roster?.workDaysFor(person) ?? <RosterDay>[];
      final upcoming = days.where((d) => d.date.compareTo(today) >= 0).toList();
      final past = days
          .where((d) => d.date.compareTo(today) < 0)
          .toList()
          .reversed
          .toList();
      final next = work.where((d) => d.date.compareTo(today) >= 0).firstOrNull;
      final todayRow = days.where((d) => d.date == today).firstOrNull;
      final filtered =
          roster?.employees
              .where(
                (n) => n.toLowerCase().contains(search.trim().toLowerCase()),
              )
              .toList() ??
          <String>[];
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 115),
            children: [
              Text(
                'Duty roster',
                style: style.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Your Excel roster, made clear.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: importing ? null : _import,
                icon: importing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: Text(
                  importing
                      ? 'Reading workbook…'
                      : roster == null
                      ? 'Import Excel roster'
                      : 'Replace Excel roster',
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(error!, style: TextStyle(color: scheme.error)),
                ),
              const SizedBox(height: 14),
              if (roster == null)
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.table_chart_rounded,
                        color: scheme.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'See every call and day off.',
                        style: style.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Import an .xlsx or .xls roster. The sheet needs a Date / التاريخ column and department columns with staff names. Pick a name to see workdays, rest days, and the next call.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The parsed roster stays on this device.',
                        style: style.labelMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              roster.sourceName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: style.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        roster.sheetName +
                            ' · ' +
                            roster.employees.length.toString() +
                            ' people · ' +
                            days.length.toString() +
                            ' dated rows',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      Text(
                        days.first.date + ' → ' + days.last.date,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 23),
                Text(
                  'Choose a person',
                  style: style.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search names',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => search = value),
                ),
                const SizedBox(height: 11),
                if (filtered.isEmpty)
                  const Text('No matching names.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    children: [
                      for (final name in filtered)
                        ChoiceChip(
                          label: Text(name),
                          selected: name == person,
                          onSelected: (_) => store.selectEmployee(name),
                        ),
                    ],
                  ),
                const SizedBox(height: 24),
                Text(
                  person,
                  style: style.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        work.length.toString(),
                        'Workdays',
                        Icons.work_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _Metric(
                        (days.length - work.length).toString(),
                        'Days off',
                        Icons.weekend_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                _Panel(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: todayRow?.departmentFor(person) == null
                            ? scheme.secondaryContainer
                            : scheme.primaryContainer,
                        child: Icon(
                          todayRow == null
                              ? Icons.event_busy_outlined
                              : todayRow.departmentFor(person) == null
                              ? Icons.weekend_outlined
                              : Icons.medical_services_outlined,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today',
                              style: style.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              todayRow == null
                                  ? 'Outside imported roster'
                                  : todayRow.departmentFor(person) ?? 'Day off',
                              style: style.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                _Panel(
                  child: Row(
                    children: [
                      Icon(Icons.next_plan_outlined, color: scheme.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next call',
                              style: style.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              next == null
                                  ? 'None in this roster'
                                  : _pretty(next.date) +
                                        ' · ' +
                                        (next.departmentFor(person) ?? ''),
                              style: style.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 23),
                Text(
                  'Schedule',
                  style: style.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Days shown are within the imported workbook.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                if (upcoming.isEmpty)
                  const ListTile(title: Text('No future dates in this roster.'))
                else
                  for (final row in upcoming)
                    _DayTile(row: row, person: person),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => setState(() => showPast = !showPast),
                  icon: Icon(
                    showPast ? Icons.expand_less : Icons.history_rounded,
                  ),
                  label: Text(
                    showPast
                        ? 'Hide past days'
                        : 'Past days (' + past.length.toString() + ')',
                  ),
                ),
                if (showPast)
                  for (final row in past) _DayTile(row: row, person: person),
              ],
            ],
          ),
        ),
      );
    },
  );
}

String _pretty(String raw) =>
    DateFormat('EEE, MMM d').format(DateTime.parse(raw));

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label, this.icon);
  final String value, label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(height: 9),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.row, required this.person});
  final RosterDay row;
  final String person;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final department = row.departmentFor(person);
    return Card(
      elevation: 0,
      color: department == null
          ? scheme.surfaceContainerLow
          : scheme.primaryContainer.withValues(alpha: .58),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: department == null
              ? scheme.secondaryContainer
              : scheme.primaryContainer,
          child: Icon(
            department == null
                ? Icons.weekend_outlined
                : Icons.medical_services_outlined,
            size: 20,
          ),
        ),
        title: Text(
          department ?? 'Day off',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          _pretty(row.date) +
              (row.group.isEmpty ? '' : ' · Group ' + row.group),
        ),
        trailing: Text(
          department == null ? 'REST' : 'ON',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: department == null
                ? scheme.onSurfaceVariant
                : scheme.primary,
          ),
        ),
      ),
    );
  }
}
