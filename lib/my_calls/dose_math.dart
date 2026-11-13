enum DoseBasis { perDose, perDay }

class DoseInput {
  const DoseInput({
    required this.drug,
    required this.source,
    required this.weightKg,
    required this.rateMgPerKg,
    required this.basis,
    required this.dosesPerDay,
    required this.strengthMg,
    required this.strengthMl,
    this.maxMgPerDose,
    this.maxMgPerDay,
  });
  final String drug, source;
  final double weightKg, rateMgPerKg, strengthMg, strengthMl;
  final int dosesPerDay;
  final DoseBasis basis;
  final double? maxMgPerDose, maxMgPerDay;
}

class DoseResult {
  const DoseResult({
    required this.rawMgPerDose,
    required this.mgPerDose,
    required this.mlPerDose,
    required this.mgPerDay,
    required this.mgPerMl,
    required this.maximumApplied,
  });
  final double rawMgPerDose, mgPerDose, mlPerDose, mgPerDay, mgPerMl;
  final bool maximumApplied;
}

/// Arithmetic only. The user supplies the clinically verified order and formulation.
class DoseCalculator {
  static DoseResult calculate(DoseInput input) {
    bool valid(double value) => value.isFinite && value > 0;
    if (input.drug.trim().isEmpty || input.source.trim().isEmpty)
      throw const FormatException(
        'Drug name and verified source are required.',
      );
    if (!valid(input.weightKg) || input.weightKg < .3 || input.weightKg > 300)
      throw const FormatException('Check weight in kilograms (0.3–300).');
    if (!valid(input.rateMgPerKg) ||
        !valid(input.strengthMg) ||
        !valid(input.strengthMl))
      throw const FormatException(
        'Dose rate and formulation strength must be positive.',
      );
    if (input.dosesPerDay < 1 || input.dosesPerDay > 24)
      throw const FormatException('Doses per day must be 1–24.');
    if (input.maxMgPerDose != null && !valid(input.maxMgPerDose!))
      throw const FormatException('Check the maximum per dose.');
    if (input.maxMgPerDay != null && !valid(input.maxMgPerDay!))
      throw const FormatException('Check the maximum per day.');
    final raw =
        input.weightKg *
        input.rateMgPerKg /
        (input.basis == DoseBasis.perDay ? input.dosesPerDay : 1);
    var perDose = raw;
    if (input.maxMgPerDose case final max?) {
      if (perDose > max) perDose = max;
    }
    if (input.maxMgPerDay case final max?) {
      if (perDose * input.dosesPerDay > max) perDose = max / input.dosesPerDay;
    }
    final concentration = input.strengthMg / input.strengthMl;
    final volume = perDose / concentration;
    if (!volume.isFinite || !perDose.isFinite || volume <= 0)
      throw const FormatException('Check the entered units and concentration.');
    if (volume < .01 || volume > 1000)
      throw const FormatException(
        'Calculated volume is outside the display range; verify dilution and order.',
      );
    return DoseResult(
      rawMgPerDose: raw,
      mgPerDose: perDose,
      mlPerDose: volume,
      mgPerDay: perDose * input.dosesPerDay,
      mgPerMl: concentration,
      maximumApplied: perDose < raw,
    );
  }
}
