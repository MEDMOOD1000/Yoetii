import 'package:flutter/material.dart';

import 'dose_math.dart';

class DoseTab extends StatefulWidget {
  const DoseTab({super.key});
  @override
  State<DoseTab> createState() => _DoseTabState();
}

class _DoseTabState extends State<DoseTab> {
  final _drug = TextEditingController(),
      _source = TextEditingController(),
      _weight = TextEditingController(),
      _rate = TextEditingController(),
      _count = TextEditingController(text: '1'),
      _strength = TextEditingController(),
      _volume = TextEditingController(text: '1'),
      _maxDose = TextEditingController(),
      _maxDay = TextEditingController();
  DoseBasis _basis = DoseBasis.perDose;
  DoseResult? _result;
  String? _error;
  @override
  void dispose() {
    for (final c in [
      _drug,
      _source,
      _weight,
      _rate,
      _count,
      _strength,
      _volume,
      _maxDose,
      _maxDay,
    ])
      c.dispose();
    super.dispose();
  }

  double _number(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? double.nan;
  double? _optional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : _number(c);
  void _calculate() {
    try {
      final input = DoseInput(
        drug: _drug.text,
        source: _source.text,
        weightKg: _number(_weight),
        rateMgPerKg: _number(_rate),
        basis: _basis,
        dosesPerDay: int.tryParse(_count.text.trim()) ?? 0,
        strengthMg: _number(_strength),
        strengthMl: _number(_volume),
        maxMgPerDose: _optional(_maxDose),
        maxMgPerDay: _optional(_maxDay),
      );
      final result = DoseCalculator.calculate(input);
      setState(() {
        _result = result;
        _error = null;
      });
      FocusManager.instance.primaryFocus?.unfocus();
    } on FormatException catch (e) {
      setState(() {
        _result = null;
        _error = e.message;
      });
    }
  }

  String _fmt(double n) =>
      n.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 110),
          children: [
            Text(
              'Dose math',
              style: text.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'A clear calculation from a verified order.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Enter the prescribed rate and the exact formulation label. The app does not choose a drug, indication, route, age adjustment, or dose for you.',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onTertiaryContainer,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _Section(
              title: 'ORDER',
              children: [
                _Field(
                  label: 'Drug / preparation',
                  controller: _drug,
                  hint: 'Name as written on the order',
                ),
                _Field(
                  label: 'Verified source or order reference',
                  controller: _source,
                  hint: 'e.g. signed order / protocol version',
                ),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Measured weight (kg)',
                        controller: _weight,
                        hint: 'kg',
                        numeric: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Field(
                        label: 'Doses per day',
                        controller: _count,
                        hint: '1–24',
                        numeric: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'How is the prescribed rate written?',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<DoseBasis>(
                  segments: const [
                    ButtonSegment(
                      value: DoseBasis.perDose,
                      label: Text('mg/kg/dose'),
                    ),
                    ButtonSegment(
                      value: DoseBasis.perDay,
                      label: Text('mg/kg/day'),
                    ),
                  ],
                  selected: {_basis},
                  onSelectionChanged: (s) => setState(() => _basis = s.first),
                ),
                const SizedBox(height: 14),
                _Field(
                  label: _basis == DoseBasis.perDose
                      ? 'Prescribed mg/kg per dose'
                      : 'Prescribed mg/kg per day',
                  controller: _rate,
                  hint: 'mg/kg',
                  numeric: true,
                ),
              ],
            ),
            const SizedBox(height: 15),
            _Section(
              title: 'FORMULATION',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Amount (mg)',
                        controller: _strength,
                        hint: 'mg on label',
                        numeric: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Field(
                        label: 'In volume (mL)',
                        controller: _volume,
                        hint: 'mL on label',
                        numeric: true,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Example format: 125 mg in 5 mL. Use the concentration actually supplied.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _Section(
              title: 'LIMITS · IF ORDERED',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Max mg / dose',
                        controller: _maxDose,
                        hint: 'Optional',
                        numeric: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Field(
                        label: 'Max mg / day',
                        controller: _maxDay,
                        hint: 'Optional',
                        numeric: true,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Blank means no maximum was entered. It does not mean no maximum exists.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_rounded),
                label: const Text(
                  'Calculate',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 54)),
              ),
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
            if (_result != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _DoseOutput(
                  result: _result!,
                  fmt: _fmt,
                  drug: _drug.text.trim(),
                  source: _source.text.trim(),
                  count: _count.text.trim(),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              'Calculation support only. Check patient age, renal/hepatic function, indication, route, allergy, formulation, protocol limits and rounding with a qualified clinician or pharmacist before administration.',
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.numeric = false,
  });
  final String label, hint;
  final TextEditingController controller;
  final bool numeric;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );
}

class _DoseOutput extends StatelessWidget {
  const _DoseOutput({
    required this.result,
    required this.fmt,
    required this.drug,
    required this.source,
    required this.count,
  });
  final DoseResult result;
  final String Function(double) fmt;
  final String drug, source, count;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CALCULATED · ' + drug.toUpperCase(),
            style: text.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            fmt(result.mgPerDose) + ' mg',
            style: text.headlineMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'per dose',
            style: text.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 13),
          Text(
            fmt(result.mlPerDose) + ' mL per dose',
            style: text.titleLarge?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: scheme.onPrimaryContainer.withValues(alpha: .3)),
          Text(
            'Strength: ' +
                fmt(result.mgPerMl) +
                ' mg/mL · ' +
                count +
                ' doses/day · ' +
                fmt(result.mgPerDay) +
                ' mg/day',
            style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
          ),
          if (result.maximumApplied)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(
                'Maximum applied: raw calculation was ' +
                    fmt(result.rawMgPerDose) +
                    ' mg/dose.',
                style: text.bodySmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Source: ' + source,
            style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 7),
          Text(
            'Do not use this display as an administration order.',
            style: text.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
