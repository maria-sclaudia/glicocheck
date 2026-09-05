/// Detalhes matemáticos passo a passo para exibição e conferência.
class CalculationBreakdown {
  final String carbohydrateFormula;
  final String carbohydrateResultText;
  final String correctionFormula;
  final String correctionResultText;
  final String totalFormula;
  final String totalResultText;
  final String roundingFormula;

  const CalculationBreakdown({
    required this.carbohydrateFormula,
    required this.carbohydrateResultText,
    required this.correctionFormula,
    required this.correctionResultText,
    required this.totalFormula,
    required this.totalResultText,
    required this.roundingFormula,
  });
}

/// Resultado completo e detalhado do cálculo de bolus de insulina.
class BolusCalculationResult {
  final double? currentGlucose;
  final double? carbohydrates;
  final double targetMin;
  final double targetMax;
  final double targetGlucose;
  final double insulinSensitivity;
  final double carbohydrateRatio;
  final double carbohydrateInsulin;
  final double correctionInsulin;
  final double rawTotalInsulin;
  final double totalInsulin;
  final double insulinIncrement;
  final double maxBolus;
  final bool isBelowTarget;
  final bool isWithinTarget;
  final bool isAboveTarget;
  final bool isMaxBolusExceeded;
  final String configurationUsed;
  final DateTime timestamp;
  final CalculationBreakdown breakdown;

  const BolusCalculationResult({
    required this.currentGlucose,
    required this.carbohydrates,
    required this.targetMin,
    required this.targetMax,
    required this.targetGlucose,
    required this.insulinSensitivity,
    required this.carbohydrateRatio,
    required this.carbohydrateInsulin,
    required this.correctionInsulin,
    required this.rawTotalInsulin,
    required this.totalInsulin,
    required this.insulinIncrement,
    required this.maxBolus,
    required this.isBelowTarget,
    required this.isWithinTarget,
    required this.isAboveTarget,
    required this.isMaxBolusExceeded,
    required this.configurationUsed,
    required this.timestamp,
    required this.breakdown,
  });

  /// Diferença da glicemia em relação ao alvo (se informada)
  double? get glucoseDifference =>
      currentGlucose != null ? (currentGlucose! - targetGlucose) : null;

  /// Helper de formatação decimal limpa (ex: 4.0 -> "4,0", 2.35 -> "2,35")
  static String formatUnits(double value, [int maxDecimals = 2]) {
    String formatted = value.toStringAsFixed(maxDecimals);
    // Se terminar com .00, remover
    if (formatted.contains('.')) {
      while (formatted.endsWith('0') && formatted.split('.')[1].length > 1) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
    }
    return formatted.replaceAll('.', ',');
  }
}
