/// Registro histórico de um cálculo de bolus realizado.
class BolusHistoryItem {
  final String id;
  final DateTime timestamp;
  final double? glucose;
  final double? carbohydrates;
  final double carbohydrateInsulin;
  final double correctionInsulin;
  final double totalInsulin;
  final String configurationUsed;
  final double targetMin;
  final double targetMax;
  final double insulinSensitivity;
  final double carbohydrateRatio;

  const BolusHistoryItem({
    required this.id,
    required this.timestamp,
    this.glucose,
    this.carbohydrates,
    required this.carbohydrateInsulin,
    required this.correctionInsulin,
    required this.totalInsulin,
    required this.configurationUsed,
    required this.targetMin,
    required this.targetMax,
    required this.insulinSensitivity,
    required this.carbohydrateRatio,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'glucose': glucose,
      'carbohydrates': carbohydrates,
      'carbohydrateInsulin': carbohydrateInsulin,
      'correctionInsulin': correctionInsulin,
      'totalInsulin': totalInsulin,
      'configurationUsed': configurationUsed,
      'targetMin': targetMin,
      'targetMax': targetMax,
      'insulinSensitivity': insulinSensitivity,
      'carbohydrateRatio': carbohydrateRatio,
    };
  }

  factory BolusHistoryItem.fromJson(Map<String, dynamic> json) {
    return BolusHistoryItem(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      glucose: (json['glucose'] as num?)?.toDouble(),
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble(),
      carbohydrateInsulin: (json['carbohydrateInsulin'] as num).toDouble(),
      correctionInsulin: (json['correctionInsulin'] as num).toDouble(),
      totalInsulin: (json['totalInsulin'] as num).toDouble(),
      configurationUsed: json['configurationUsed'] as String? ?? '',
      targetMin: (json['targetMin'] as num?)?.toDouble() ?? 80.0,
      targetMax: (json['targetMax'] as num?)?.toDouble() ?? 120.0,
      insulinSensitivity:
          (json['insulinSensitivity'] as num?)?.toDouble() ?? 50.0,
      carbohydrateRatio:
          (json['carbohydrateRatio'] as num?)?.toDouble() ?? 10.0,
    );
  }
}
