import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/models/insulin_settings.dart';
import 'package:personal_app/services/bolus_calculator_service.dart';

void main() {
  const service = BolusCalculatorService();

  // Configuração base comum para testes
  const baseSettings = InsulinSettings(
    targetMin: 80.0,
    targetMax: 120.0,
    insulinSensitivity: 50.0,
    carbohydrateRatio: 10.0,
    insulinIncrement: 0.1,
    maxBolus: 15.0,
    useTimeBlocks: false, // para testes diretos de valores globais
  );

  group('Especificação Oficial de Cálculos de Bolus (Testes 1 a 7)', () {
    test('Teste 1 — Somente carboidratos (40g, Relação 10 g/U -> 4 U)', () {
      final result = service.calculateBolus(
        carbohydrates: 40.0,
        settings: baseSettings,
      );

      expect(result.carbohydrateInsulin, closeTo(4.0, 0.001));
      expect(result.correctionInsulin, closeTo(0.0, 0.001));
      expect(result.totalInsulin, closeTo(4.0, 0.001));
      expect(result.currentGlucose, isNull);
    });

    test('Teste 2 — Glicemia dentro do alvo (100 mg/dL, Faixa 80-120 -> Correção 0 U)', () {
      final result = service.calculateBolus(
        glucose: 100.0,
        settings: baseSettings,
      );

      expect(result.targetGlucose, closeTo(100.0, 0.001));
      expect(result.isWithinTarget, isTrue);
      expect(result.isAboveTarget, isFalse);
      expect(result.isBelowTarget, isFalse);
      expect(result.correctionInsulin, closeTo(0.0, 0.001));
      expect(result.carbohydrateInsulin, closeTo(0.0, 0.001));
      expect(result.totalInsulin, closeTo(0.0, 0.001));
    });

    test('Teste 3 — Glicemia acima do alvo (200 mg/dL, Faixa 80-120, Sens 50 -> Correção 2 U)', () {
      final result = service.calculateBolus(
        glucose: 200.0,
        settings: baseSettings,
      );

      expect(result.targetGlucose, closeTo(100.0, 0.001));
      expect(result.isAboveTarget, isTrue);
      expect(result.correctionInsulin, closeTo(2.0, 0.001));
      expect(result.carbohydrateInsulin, closeTo(0.0, 0.001));
      expect(result.totalInsulin, closeTo(2.0, 0.001));
    });

    test('Teste 4 — Glicemia + carboidratos (200 mg/dL, 40g -> Carbs 4 U, Corr 2 U, Total 6 U)', () {
      final result = service.calculateBolus(
        glucose: 200.0,
        carbohydrates: 40.0,
        settings: baseSettings,
      );

      expect(result.carbohydrateInsulin, closeTo(4.0, 0.001));
      expect(result.correctionInsulin, closeTo(2.0, 0.001));
      expect(result.rawTotalInsulin, closeTo(6.0, 0.001));
      expect(result.totalInsulin, closeTo(6.0, 0.001));
    });

    test('Teste 5 — Glicemia abaixo do alvo sem carboidratos (60 mg/dL, Faixa 80-120 -> Correção -0.8 U, Total 0 U seguro)', () {
      final result = service.calculateBolus(
        glucose: 60.0,
        settings: baseSettings,
      );

      expect(result.isBelowTarget, isTrue);
      expect(result.isWithinTarget, isFalse);
      expect(result.isAboveTarget, isFalse);
      expect(result.correctionInsulin, closeTo(-0.8, 0.001));
      expect(result.totalInsulin, closeTo(0.0, 0.001));
    });

    test('Teste 5b — Glicemia abaixo do alvo com carboidratos (74 mg/dL, 70g, Relação 12 g/U, Sens 50 -> 5.3 U)', () {
      final settings = baseSettings.copyWith(
        carbohydrateRatio: 12.0,
      );
      final result = service.calculateBolus(
        glucose: 74.0,
        carbohydrates: 70.0,
        settings: settings,
      );

      // Carbs = 70 / 12 = 5.833 U
      // Corr = (74 - 100) / 50 = -0.52 U
      // Total = 5.833 - 0.52 = 5.313 -> 5.3 U
      expect(result.isBelowTarget, isTrue);
      expect(result.carbohydrateInsulin, closeTo(5.833, 0.01));
      expect(result.correctionInsulin, closeTo(-0.52, 0.01));
      expect(result.totalInsulin, closeTo(5.3, 0.001));
    });

    test('Teste 6 — Glicemia dentro do alvo + carboidratos (110 mg/dL, 50g -> Carbs 5 U, Corr 0 U, Total 5 U)', () {
      final result = service.calculateBolus(
        glucose: 110.0,
        carbohydrates: 50.0,
        settings: baseSettings,
      );

      expect(result.isWithinTarget, isTrue);
      expect(result.carbohydrateInsulin, closeTo(5.0, 0.001));
      expect(result.correctionInsulin, closeTo(0.0, 0.001));
      expect(result.totalInsulin, closeTo(5.0, 0.001));
    });

    test('Teste 7 — Glicemia alta + carboidratos (250 mg/dL, 60g -> Carbs 6 U, Corr 3 U, Total 9 U)', () {
      final result = service.calculateBolus(
        glucose: 250.0,
        carbohydrates: 60.0,
        settings: baseSettings,
      );

      expect(result.targetGlucose, closeTo(100.0, 0.001));
      expect(result.carbohydrateInsulin, closeTo(6.0, 0.001));
      expect(result.correctionInsulin, closeTo(3.0, 0.001));
      expect(result.totalInsulin, closeTo(9.0, 0.001));
    });
  });

  group('Testes de Validação e Limites', () {
    test('Nenhum campo informado deve lançar BolusValidationException', () {
      expect(
        () => service.calculateBolus(settings: baseSettings),
        throwsA(isA<BolusValidationException>().having(
          (e) => e.message,
          'message',
          contains('Informe a glicemia ou a quantidade de carboidratos'),
        )),
      );
    });

    test('Glicemia negativa deve lançar BolusValidationException', () {
      expect(
        () => service.calculateBolus(glucose: -50.0, settings: baseSettings),
        throwsA(isA<BolusValidationException>()),
      );
    });

    test('Carboidratos negativos deve lançar BolusValidationException', () {
      expect(
        () => service.calculateBolus(carbohydrates: -10.0, settings: baseSettings),
        throwsA(isA<BolusValidationException>()),
      );
    });

    test('Permitir 0 g de carboidratos com glicemia válida', () {
      final result = service.calculateBolus(
        glucose: 200.0,
        carbohydrates: 0.0,
        settings: baseSettings,
      );

      expect(result.carbohydrateInsulin, closeTo(0.0, 0.001));
      expect(result.correctionInsulin, closeTo(2.0, 0.001));
      expect(result.totalInsulin, closeTo(2.0, 0.001));
    });
  });

  group('Incremento de Insulina e Dose Máxima', () {
    test('Incremento padrão parametrizado deve ser 0.1 U', () {
      final initial = InsulinSettings.initialDefault();
      expect(initial.insulinIncrement, 0.1);
    });

    test('Incremento de 0.5 U com resultado matemático de 2.37 U -> 2.5 U', () {
      final settings = baseSettings.copyWith(
        insulinIncrement: 0.5,
      );

      // Glicemia 218.5 -> (218.5 - 100) / 50 = 2.37 U
      final result = service.calculateBolus(
        glucose: 218.5,
        settings: settings,
      );

      expect(result.rawTotalInsulin, closeTo(2.37, 0.01));
      expect(result.totalInsulin, closeTo(2.5, 0.001));
    });

    test('Incremento de 0.1 U com resultado de 2.37 U -> 2.4 U', () {
      final settings = baseSettings.copyWith(
        insulinIncrement: 0.1,
      );

      final result = service.calculateBolus(
        glucose: 218.5,
        settings: settings,
      );

      expect(result.totalInsulin, closeTo(2.4, 0.001));
    });

    test('Incremento de 1.0 U com resultado de 2.37 U -> 2.0 U', () {
      final settings = baseSettings.copyWith(
        insulinIncrement: 1.0,
      );

      final result = service.calculateBolus(
        glucose: 218.5,
        settings: settings,
      );

      expect(result.totalInsulin, closeTo(2.0, 0.001));
    });

    test('Alerta de dose máxima quando cálculo ultrapassa limite (12 U > Max 10 U)', () {
      final settings = baseSettings.copyWith(
        maxBolus: 10.0,
      );

      // 120 g carbs com relação 10 -> 12 U
      final result = service.calculateBolus(
        carbohydrates: 120.0,
        settings: settings,
      );

      expect(result.totalInsulin, closeTo(12.0, 0.001));
      expect(result.isMaxBolusExceeded, isTrue);
      expect(result.maxBolus, closeTo(10.0, 0.001));
    });
  });

  group('Blocos de Horário (2 Blocos Parametrizados)', () {
    final settingsWithBlocks = InsulinSettings.initialDefault();

    test('1º Bloco — 00:00 às 05:00 (Alvo 100-140, Relação 11 g/U, Sens 50 mg/dL/U)', () {
      final time = DateTime(2026, 8, 15, 3, 30);
      final result = service.calculateBolus(
        glucose: 170.0,
        carbohydrates: 33.0,
        settings: settingsWithBlocks,
        calculationTime: time,
      );

      // Alvo central = (100 + 140) / 2 = 120 mg/dL
      // Carbs = 33 / 11 = 3.0 U
      // Correção = (170 - 120) / 50 = 50 / 50 = 1.0 U
      // Total = 4.0 U
      expect(result.configurationUsed, contains('00:00 – 05:00'));
      expect(result.targetMin, closeTo(100.0, 0.001));
      expect(result.targetMax, closeTo(140.0, 0.001));
      expect(result.targetGlucose, closeTo(120.0, 0.001));
      expect(result.carbohydrateRatio, closeTo(11.0, 0.001));
      expect(result.insulinSensitivity, closeTo(50.0, 0.001));
      expect(result.carbohydrateInsulin, closeTo(3.0, 0.001));
      expect(result.correctionInsulin, closeTo(1.0, 0.001));
      expect(result.totalInsulin, closeTo(4.0, 0.001));
    });

    test('2º Bloco — 05:00 às 00:00 (Alvo 80-120, Relação 12 g/U, Sens 50 mg/dL/U)', () {
      final time = DateTime(2026, 8, 15, 14, 0);
      final result = service.calculateBolus(
        glucose: 200.0,
        carbohydrates: 48.0,
        settings: settingsWithBlocks,
        calculationTime: time,
      );

      // Alvo central = (80 + 120) / 2 = 100 mg/dL
      // Carbs = 48 / 12 = 4.0 U
      // Correção = (200 - 100) / 50 = 100 / 50 = 2.0 U
      // Total = 6.0 U
      expect(result.configurationUsed, contains('05:00 – 00:00'));
      expect(result.targetMin, closeTo(80.0, 0.001));
      expect(result.targetMax, closeTo(120.0, 0.001));
      expect(result.targetGlucose, closeTo(100.0, 0.001));
      expect(result.carbohydrateRatio, closeTo(12.0, 0.001));
      expect(result.insulinSensitivity, closeTo(50.0, 0.001));
      expect(result.carbohydrateInsulin, closeTo(4.0, 0.001));
      expect(result.correctionInsulin, closeTo(2.0, 0.001));
      expect(result.totalInsulin, closeTo(6.0, 0.001));
    });
  });
}
