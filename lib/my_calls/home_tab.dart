import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'store.dart';

class CallsHome extends StatefulWidget {
  const CallsHome({
    super.key,
    required this.openShifts,
    required this.openDoses,
    required this.openNotes,
  });
  final VoidCallback openShifts, openDoses, openNotes;
  @override
  State<CallsHome> createState() => _CallsHomeState();
}

class _CallsHomeState extends State<CallsHome> {
  @override
  void initState() {
    super.initState();
    MyCallsStore.instance.load();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: MyCallsStore.instance,
    builder: (context, _) {
      final store = MyCallsStore.instance;
      final now = DateTime.now();
      final today = dayKey(now);
      final roster = store.roster;
      final person = store.selectedEmployee;
      final upcoming =
          roster
              ?.workDaysFor(person)
              .where((d) => d.date.compareTo(today) >= 0)
              .toList() ??
          [];
      final todayShifts =
          roster?.days
              .where((d) => d.date == today && d.departmentFor(person) != null)
              .length ??
          0;
      final activeNotes = store.notes.where((n) => !n.archived).length;
      final scheme = Theme.of(context).colorScheme;
      final text = Theme.of(context).textTheme;
      final quote = store.quoteMode == 'quran'
          ? const [
              ('وَقُل رَّبِّ زِدْنِي عِلْمًا', 'سورة طه · 114'),
              ('إِنَّ مَعَ الْعُسْرِ يُسْرًا', 'سورة الشرح · 6'),
            ]
          : const [
              ('Small details make safer care.', 'MY CALLS'),
              ('Take a clear note. Make a careful decision.', 'MY CALLS'),
              ('A calm shift starts with a plan.', 'MY CALLS'),
            ];
      final selectedQuote = quote[now.day % quote.length];
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 34, 22, 115),
            children: [
              Text(
                'MY CALLS',
                style: text.labelLarge?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your shift,\nin focus.',
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEEE, MMMM d').format(now),
                style: text.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer,
                      scheme.tertiaryContainer.withValues(alpha: .68),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: scheme.onPrimaryContainer.withValues(alpha: .72),
                      size: 32,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      selectedQuote.$1,
                      style: text.headlineSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      selectedQuote.$2,
                      style: text.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: .78),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      value: todayShifts.toString(),
                      label: 'Today’s calls',
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Metric(
                      value: activeNotes.toString(),
                      label: 'Your notes',
                      icon: Icons.sticky_note_2_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 27),
              Text(
                'Up next',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Material(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: widget.openShifts,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(
                            Icons.medical_services_outlined,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                upcoming.isEmpty
                                    ? 'No upcoming shift'
                                    : (upcoming.first.departmentFor(person) ??
                                          'Shift'),
                                style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                upcoming.isEmpty
                                    ? 'Import a roster in Duty'
                                    : DateFormat('EEE, MMM d').format(
                                            DateTime.parse(upcoming.first.date),
                                          ) +
                                          ' · ' +
                                          person,
                                style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Quick access',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Quick(
                      label: 'Dose math',
                      icon: Icons.calculate_outlined,
                      onTap: widget.openDoses,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Quick(
                      label: 'Notes',
                      icon: Icons.lightbulb_outline_rounded,
                      onTap: widget.openNotes,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon});
  final String value, label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary, size: 21),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
