import '../core/constants/app_constants.dart';
import 'time_block.dart';

/// Parâmetros ativos para um momento específico (do bloco de horário ou global).
class ActiveInsulinParameters {
  final double targetMin;
  final double targetMax;
  final double insulinSensitivity;
  final double carbohydrateRatio;
  final TimeBlock? activeBlock;
  final String sourceDescription;

  const ActiveInsulinParameters({
    required this.targetMin,
    required this.targetMax,
    required this.insulinSensitivity,
    required this.carbohydrateRatio,
    this.activeBlock,
    required this.sourceDescription,
  });

  double get targetGlucose => (targetMin + targetMax) / 2.0;

  /// Faixa-alvo compacta (ex: "80–120 mg/dL")
  String targetRangeCompact([String unit = 'mg/dL']) {
    final minStr = targetMin == targetMin.roundToDouble()
        ? targetMin.toInt().toString()
        : targetMin.toString().replaceAll('.', ',');
    final maxStr = targetMax == targetMax.roundToDouble()
        ? targetMax.toInt().toString()
        : targetMax.toString().replaceAll('.', ',');
    return '$minStr–$maxStr $unit';
  }

  /// Relação insulina/carboidratos formatada (ex: "1 U p/ 12g")
  String get carbRatioFormatted {
    final ratioStr = carbohydrateRatio == carbohydrateRatio.roundToDouble()
        ? carbohydrateRatio.toInt().toString()
        : carbohydrateRatio.toString().replaceAll('.', ',');
    return '1 U p/ ${ratioStr}g';
  }

  /// Sensibilidade à insulina formatada (ex: "1 U p/ 50 mg/dL")
  String insulinSensitivityFormatted([String unit = 'mg/dL']) {
    final sensStr = insulinSensitivity == insulinSensitivity.roundToDouble()
        ? insulinSensitivity.toInt().toString()
        : insulinSensitivity.toString().replaceAll('.', ',');
    return '1 U p/ $sensStr $unit';
  }
}

/// Configurações gerais de insulina e blocos de horário persistidos.
class InsulinSettings {
  final String glucoseUnit;
  final double targetMin;
  final double targetMax;
  final double insulinSensitivity;
  final double carbohydrateRatio;
  final double insulinIncrement;
  final double maxBolus;
  final bool useTimeBlocks;
  final List<TimeBlock> timeBlocks;

  const InsulinSettings({
    this.glucoseUnit = 'mg/dL',
    required this.targetMin,
    required this.targetMax,
    required this.insulinSensitivity,
    required this.carbohydrateRatio,
    required this.insulinIncrement,
    required this.maxBolus,
    this.useTimeBlocks = true,
    this.timeBlocks = const [],
  });

  /// Glicemia alvo central calculada a partir da faixa global
  double get targetGlucose => (targetMin + targetMax) / 2.0;

  /// Retorna os parâmetros ativos para um dado horário (encontrando o bloco ou fallback padrão)
  ActiveInsulinParameters getActiveParameters([DateTime? time]) {
    final now = time ?? DateTime.now();

    if (useTimeBlocks && timeBlocks.isNotEmpty) {
      for (final block in timeBlocks) {
        if (block.containsDateTime(now)) {
          return ActiveInsulinParameters(
            targetMin: block.targetMin,
            targetMax: block.targetMax,
            insulinSensitivity: block.insulinSensitivity,
            carbohydrateRatio: block.carbohydrateRatio,
            activeBlock: block,
            sourceDescription: block.label.isNotEmpty
                ? '${block.label} (${block.timeRangeFormatted})'
                : block.timeRangeFormatted,
          );
        }
      }
    }

    return ActiveInsulinParameters(
      targetMin: targetMin,
      targetMax: targetMax,
      insulinSensitivity: insulinSensitivity,
      carbohydrateRatio: carbohydrateRatio,
      activeBlock: null,
      sourceDescription: 'Configuração Padrão',
    );
  }

  /// Configurações padrão iniciais (configuráveis pelo usuário, sem hardcoding no fluxo clínico)
  factory InsulinSettings.initialDefault() {
    return const InsulinSettings(
      glucoseUnit: 'mg/dL',
      targetMin: 80.0,
      targetMax: 120.0,
      insulinSensitivity: 50.0,
      carbohydrateRatio: 12.0,
      insulinIncrement: AppConstants.defaultInsulinIncrement,
      maxBolus: 10.0,
      useTimeBlocks: true,
      timeBlocks: [
        TimeBlock(
          id: 'block_1',
          label: 'Madrugada',
          startHour: 0,
          startMinute: 0,
          endHour: 5,
          endMinute: 0,
          targetMin: 100.0,
          targetMax: 140.0,
          insulinSensitivity: 50.0,
          carbohydrateRatio: 11.0,
        ),
        TimeBlock(
          id: 'block_2',
          label: 'Dia',
          startHour: 5,
          startMinute: 0,
          endHour: 0,
          endMinute: 0,
          targetMin: 80.0,
          targetMax: 120.0,
          insulinSensitivity: 50.0,
          carbohydrateRatio: 12.0,
        ),
      ],
    );
  }

  InsulinSettings copyWith({
    String? glucoseUnit,
    double? targetMin,
    double? targetMax,
    double? insulinSensitivity,
    double? carbohydrateRatio,
    double? insulinIncrement,
    double? maxBolus,
    bool? useTimeBlocks,
    List<TimeBlock>? timeBlocks,
  }) {
    return InsulinSettings(
      glucoseUnit: glucoseUnit ?? this.glucoseUnit,
      targetMin: targetMin ?? this.targetMin,
      targetMax: targetMax ?? this.targetMax,
      insulinSensitivity: insulinSensitivity ?? this.insulinSensitivity,
      carbohydrateRatio: carbohydrateRatio ?? this.carbohydrateRatio,
      insulinIncrement: insulinIncrement ?? this.insulinIncrement,
      maxBolus: maxBolus ?? this.maxBolus,
      useTimeBlocks: useTimeBlocks ?? this.useTimeBlocks,
      timeBlocks: timeBlocks ?? this.timeBlocks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'glucoseUnit': glucoseUnit,
      'targetMin': targetMin,
      'targetMax': targetMax,
      'insulinSensitivity': insulinSensitivity,
      'carbohydrateRatio': carbohydrateRatio,
      'insulinIncrement': insulinIncrement,
      'maxBolus': maxBolus,
      'useTimeBlocks': useTimeBlocks,
      'timeBlocks': timeBlocks.map((b) => b.toJson()).toList(),
    };
  }

  factory InsulinSettings.fromJson(Map<String, dynamic> json) {
    return InsulinSettings(
      glucoseUnit: json['glucoseUnit'] as String? ?? 'mg/dL',
      targetMin: (json['targetMin'] as num?)?.toDouble() ?? 80.0,
      targetMax: (json['targetMax'] as num?)?.toDouble() ?? 120.0,
      insulinSensitivity:
          (json['insulinSensitivity'] as num?)?.toDouble() ?? 50.0,
      carbohydrateRatio:
          (json['carbohydrateRatio'] as num?)?.toDouble() ?? 10.0,
      insulinIncrement: (json['insulinIncrement'] as num?)?.toDouble() ??
          AppConstants.defaultInsulinIncrement,
      maxBolus: (json['maxBolus'] as num?)?.toDouble() ?? 10.0,
      useTimeBlocks: json['useTimeBlocks'] as bool? ?? true,
      timeBlocks: (json['timeBlocks'] as List<dynamic>?)
              ?.map((item) => TimeBlock.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
