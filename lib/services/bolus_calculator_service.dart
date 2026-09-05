import '../models/bolus_calculation_result.dart';
import '../models/insulin_settings.dart';

/// Exceção lançada quando a validação dos dados de entrada do cálculo falha.
class BolusValidationException implements Exception {
  final String message;
  const BolusValidationException(this.message);

  @override
  String toString() => message;
}

/// Serviço responsável exclusivamente pelos cálculos de dose de bolus de insulina.
class BolusCalculatorService {
  const BolusCalculatorService();

  /// Realiza o cálculo de bolus de insulina com base na glicemia, carboidratos e configurações.
  BolusCalculationResult calculateBolus({
    double? glucose,
    double? carbohydrates,
    required InsulinSettings settings,
    DateTime? calculationTime,
  }) {
    // 1. Validação básica de entrada
    if (glucose == null && carbohydrates == null) {
      throw const BolusValidationException(
        'Informe a glicemia ou a quantidade de carboidratos.',
      );
    }

    if (glucose != null && glucose < 0) {
      throw const BolusValidationException(
        'O valor da glicemia não pode ser negativo.',
      );
    }

    if (carbohydrates != null && carbohydrates < 0) {
      throw const BolusValidationException(
        'A quantidade de carboidratos não pode ser negativa.',
      );
    }

    // 2. Identificar bloco de horário ativo e carregar parâmetros
    final effectiveTime = calculationTime ?? DateTime.now();
    final params = settings.getActiveParameters(effectiveTime);

    final targetMin = params.targetMin;
    final targetMax = params.targetMax;
    final insulinSensitivity = params.insulinSensitivity;
    final carbohydrateRatio = params.carbohydrateRatio;

    // Validação dos parâmetros clínicos
    if (targetMin >= targetMax) {
      throw const BolusValidationException(
        'A faixa-alvo configurada é inválida (mínimo deve ser menor que o máximo).',
      );
    }
    if (insulinSensitivity <= 0) {
      throw const BolusValidationException(
        'O fator de sensibilidade configurado deve ser maior que zero.',
      );
    }
    if (carbohydrateRatio <= 0) {
      throw const BolusValidationException(
        'A relação carboidrato/insulina configurada deve ser maior que zero.',
      );
    }

    // 3. Insulina para carboidratos
    // FÓRMULA: insulinaCarboidratos = carboidratos / relacaoCarboidratoInsulina
    double carbohydrateInsulin = 0.0;
    if (carbohydrates != null && carbohydrates > 0) {
      carbohydrateInsulin = carbohydrates / carbohydrateRatio;
    }

    // 4. Glicemia-alvo para cálculo (ponto central da faixa)
    // FÓRMULA: glicemiaAlvo = (glicemiaAlvoMinima + glicemiaAlvoMaxima) / 2
    final targetGlucose = (targetMin + targetMax) / 2.0;

    // 5. Correção da glicemia
    double correctionInsulin = 0.0;
    bool isBelowTarget = false;
    bool isWithinTarget = false;
    bool isAboveTarget = false;

    if (glucose != null) {
      if (glucose < targetMin) {
        // Glicemia abaixo da faixa-alvo: correção negativa para abater da dose de carboidratos
        // FÓRMULA: correcao = (glicemiaAtual - glicemiaAlvo) / fatorSensibilidade
        isBelowTarget = true;
        correctionInsulin = (glucose - targetGlucose) / insulinSensitivity;
      } else if (glucose <= targetMax) {
        // Glicemia dentro da faixa-alvo: correção = 0
        isWithinTarget = true;
        correctionInsulin = 0.0;
      } else {
        // Glicemia acima do limite superior da faixa-alvo
        // FÓRMULA: correcao = (glicemiaAtual - glicemiaAlvo) / fatorSensibilidade
        isAboveTarget = true;
        correctionInsulin = (glucose - targetGlucose) / insulinSensitivity;
      }
    }

    // 6. Total Matemático (com proteção para nunca ser negativo)
    final rawSum = carbohydrateInsulin + correctionInsulin;
    final rawTotalInsulin = rawSum < 0.0 ? 0.0 : rawSum;

    // 7. Aplicação do incremento de insulina
    final increment = settings.insulinIncrement;
    final totalInsulin = roundToIncrement(rawTotalInsulin, increment);

    // 8. Verificação da dose máxima
    final isMaxBolusExceeded = totalInsulin > settings.maxBolus;

    // 9. Construção dos detalhes matemáticos para conferência
    final breakdown = _buildBreakdown(
      glucose: glucose,
      carbohydrates: carbohydrates,
      targetMin: targetMin,
      targetMax: targetMax,
      targetGlucose: targetGlucose,
      insulinSensitivity: insulinSensitivity,
      carbohydrateRatio: carbohydrateRatio,
      carbohydrateInsulin: carbohydrateInsulin,
      correctionInsulin: correctionInsulin,
      rawTotalInsulin: rawTotalInsulin,
      totalInsulin: totalInsulin,
      increment: increment,
      isBelowTarget: isBelowTarget,
      isWithinTarget: isWithinTarget,
      isAboveTarget: isAboveTarget,
    );

    return BolusCalculationResult(
      currentGlucose: glucose,
      carbohydrates: carbohydrates,
      targetMin: targetMin,
      targetMax: targetMax,
      targetGlucose: targetGlucose,
      insulinSensitivity: insulinSensitivity,
      carbohydrateRatio: carbohydrateRatio,
      carbohydrateInsulin: carbohydrateInsulin,
      correctionInsulin: correctionInsulin,
      rawTotalInsulin: rawTotalInsulin,
      totalInsulin: totalInsulin,
      insulinIncrement: increment,
      maxBolus: settings.maxBolus,
      isBelowTarget: isBelowTarget,
      isWithinTarget: isWithinTarget,
      isAboveTarget: isAboveTarget,
      isMaxBolusExceeded: isMaxBolusExceeded,
      configurationUsed: params.sourceDescription,
      timestamp: effectiveTime,
      breakdown: breakdown,
    );
  }

  /// Arredonda um valor de insulina de acordo com o incremento configurado de forma explícita e consistente.
  static double roundToIncrement(double value, double increment) {
    if (increment <= 0) return _roundToDecimals(value, 2);
    final factor = 1.0 / increment;
    final rounded = (value * factor).roundToDouble() / factor;
    return _roundToDecimals(rounded, 2);
  }

  static double _roundToDecimals(double val, int decimals) {
    final mod = 100.0; // 2 casas decimais
    return (val * mod).roundToDouble() / mod;
  }

  static String _formatNum(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  static String _formatUnit(double value) {
    return BolusCalculationResult.formatUnits(value, 2);
  }

  CalculationBreakdown _buildBreakdown({
    required double? glucose,
    required double? carbohydrates,
    required double targetMin,
    required double targetMax,
    required double targetGlucose,
    required double insulinSensitivity,
    required double carbohydrateRatio,
    required double carbohydrateInsulin,
    required double correctionInsulin,
    required double rawTotalInsulin,
    required double totalInsulin,
    required double increment,
    required bool isBelowTarget,
    required bool isWithinTarget,
    required bool isAboveTarget,
  }) {
    // 1. Detalhes Carboidratos
    final String carbFormula;
    final String carbResult;
    if (carbohydrates != null && carbohydrates > 0) {
      carbFormula =
          '${_formatNum(carbohydrates)} g ÷ ${_formatNum(carbohydrateRatio)} g/U';
      carbResult = '= ${_formatUnit(carbohydrateInsulin)} U';
    } else if (carbohydrates == 0) {
      carbFormula = '0 g ÷ ${_formatNum(carbohydrateRatio)} g/U';
      carbResult = '= 0,0 U';
    } else {
      carbFormula = 'Carboidratos não informados';
      carbResult = '0,0 U';
    }

    // 2. Detalhes Correção
    final String corrFormula;
    final String corrResult;
    if (glucose != null) {
      if (isAboveTarget) {
        final diff = glucose - targetGlucose;
        corrFormula =
            '(${_formatNum(glucose)} - ${_formatNum(targetGlucose)}) ÷ ${_formatNum(insulinSensitivity)}\n= ${_formatNum(diff)} ÷ ${_formatNum(insulinSensitivity)}';
        corrResult = '= ${_formatUnit(correctionInsulin)} U';
      } else if (isWithinTarget) {
        corrFormula =
            'Glicemia (${_formatNum(glucose)} mg/dL) dentro da faixa-alvo (${_formatNum(targetMin)}–${_formatNum(targetMax)} mg/dL)';
        corrResult = '= 0,0 U';
      } else {
        final diff = glucose - targetGlucose;
        corrFormula =
            '(${_formatNum(glucose)} - ${_formatNum(targetGlucose)}) ÷ ${_formatNum(insulinSensitivity)}\n= ${_formatNum(diff)} ÷ ${_formatNum(insulinSensitivity)} (Glicemia abaixo do alvo)';
        corrResult = '= ${_formatUnit(correctionInsulin)} U';
      }
    } else {
      corrFormula = 'Glicemia não informada';
      corrResult = '0,0 U';
    }

    // 3. Detalhes Total
    final String totalFormula;
    if (correctionInsulin < 0) {
      totalFormula =
          '${_formatUnit(carbohydrateInsulin)} U (carbs) - ${_formatUnit(correctionInsulin.abs())} U (desconto glicemia baixa)';
    } else {
      totalFormula =
          '${_formatUnit(carbohydrateInsulin)} U (carbs) + ${_formatUnit(correctionInsulin)} U (correção)';
    }
    final String totalResult;
    if (carbohydrateInsulin + correctionInsulin < 0) {
      totalResult = '= 0,0 U (mínimo 0 U)';
    } else {
      totalResult = '= ${_formatUnit(rawTotalInsulin)} U';
    }

    // 4. Detalhes Arredondamento / Incremento
    final String roundingFormula;
    if ((rawTotalInsulin - totalInsulin).abs() > 0.001) {
      roundingFormula =
          'Ajustado para incremento de ${_formatNum(increment)} U: ${_formatUnit(totalInsulin)} U';
    } else {
      roundingFormula = 'Incremento aplicado: ${_formatNum(increment)} U';
    }

    return CalculationBreakdown(
      carbohydrateFormula: carbFormula,
      carbohydrateResultText: carbResult,
      correctionFormula: corrFormula,
      correctionResultText: corrResult,
      totalFormula: totalFormula,
      totalResultText: totalResult,
      roundingFormula: roundingFormula,
    );
  }
}
