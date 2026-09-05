import 'package:flutter/material.dart';

/// Representa um bloco de horário com configurações personalizadas de insulina.
class TimeBlock {
  final String id;
  final String label;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final double targetMin;
  final double targetMax;
  final double insulinSensitivity;
  final double carbohydrateRatio;

  const TimeBlock({
    required this.id,
    required this.label,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.targetMin,
    required this.targetMax,
    required this.insulinSensitivity,
    required this.carbohydrateRatio,
  });

  /// Retorna o valor central da faixa-alvo para o bloco.
  double get targetGlucose => (targetMin + targetMax) / 2.0;

  /// Horário inicial formatado HH:mm
  String get startTimeFormatted =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  /// Horário final formatado HH:mm
  String get endTimeFormatted =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  /// Intervalo formatado (ex: "06:00 – 12:00")
  String get timeRangeFormatted => '$startTimeFormatted – $endTimeFormatted';

  /// Formatação de número decimal limpo (ex: 12.0 -> "12", 12.5 -> "12,5")
  static String formatNum(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toString().replaceAll('.', ',');
  }

  /// Faixa-alvo formatada (ex: "80 – 120 mg/dL" ou "80 mg/dL – 120 mg/dL")
  String targetRangeFormatted([String unit = 'mg/dL']) {
    return '${formatNum(targetMin)} $unit – ${formatNum(targetMax)} $unit';
  }

  /// Faixa-alvo compacta (ex: "80–120 mg/dL")
  String targetRangeCompact([String unit = 'mg/dL']) {
    return '${formatNum(targetMin)}–${formatNum(targetMax)} $unit';
  }

  /// Relação insulina/carboidratos formatada (ex: "1 U p/ 12g")
  String get carbRatioFormatted => '1 U p/ ${formatNum(carbohydrateRatio)}g';

  /// Sensibilidade à insulina formatada (ex: "1 U p/ 50 mg/dL")
  String insulinSensitivityFormatted([String unit = 'mg/dL']) =>
      '1 U p/ ${formatNum(insulinSensitivity)} $unit';

  /// Linha resumo com todas as 3 informações clínicas principais
  String summaryFormatted([String unit = 'mg/dL']) =>
      'Alvo: ${targetRangeCompact(unit)} | Relação: $carbRatioFormatted | Sensibilidade: ${insulinSensitivityFormatted(unit)}';

  /// Verifica se o horário especificado (ou DateTime) está dentro deste bloco.
  bool containsTime(int hour, int minute) {
    final currentMinutes = hour * 60 + minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    // Caso normal: mesmo dia (ex: 06:00 até 12:00)
    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
    // Caso em que cruza a meia-noite (ex: 18:00 até 06:00) ou 18:00 até 00:00 (onde 00:00 = 0)
    else if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
    // Se start == end, cobre o dia todo se ambos forem 0, senão pontual
    else {
      return currentMinutes == startMinutes;
    }
  }

  /// Verifica se um [DateTime] pertence a este bloco
  bool containsDateTime(DateTime dateTime) {
    return containsTime(dateTime.hour, dateTime.minute);
  }

  /// Verifica se um [TimeOfDay] pertence a este bloco
  bool containsTimeOfDay(TimeOfDay timeOfDay) {
    return containsTime(timeOfDay.hour, timeOfDay.minute);
  }

  TimeBlock copyWith({
    String? id,
    String? label,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    double? targetMin,
    double? targetMax,
    double? insulinSensitivity,
    double? carbohydrateRatio,
  }) {
    return TimeBlock(
      id: id ?? this.id,
      label: label ?? this.label,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      targetMin: targetMin ?? this.targetMin,
      targetMax: targetMax ?? this.targetMax,
      insulinSensitivity: insulinSensitivity ?? this.insulinSensitivity,
      carbohydrateRatio: carbohydrateRatio ?? this.carbohydrateRatio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'targetMin': targetMin,
      'targetMax': targetMax,
      'insulinSensitivity': insulinSensitivity,
      'carbohydrateRatio': carbohydrateRatio,
    };
  }

  factory TimeBlock.fromJson(Map<String, dynamic> json) {
    return TimeBlock(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      startHour: json['startHour'] as int? ?? 0,
      startMinute: json['startMinute'] as int? ?? 0,
      endHour: json['endHour'] as int? ?? 0,
      endMinute: json['endMinute'] as int? ?? 0,
      targetMin: (json['targetMin'] as num).toDouble(),
      targetMax: (json['targetMax'] as num).toDouble(),
      insulinSensitivity: (json['insulinSensitivity'] as num).toDouble(),
      carbohydrateRatio: (json['carbohydrateRatio'] as num).toDouble(),
    );
  }
}
