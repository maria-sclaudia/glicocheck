import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_app/core/constants/app_constants.dart';
import 'package:personal_app/main.dart';
import 'package:personal_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Fluxo Mobile-First: entrada de dados, navegação para ResultScreen e abas',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final settingsService = SettingsService();
    await settingsService.init();

    await tester.pumpWidget(GlicoBolusApp(settingsService: settingsService));
    await tester.pumpAndSettle();

    // 1. Verifica título, campos iniciais e barra de navegação inferior
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.byKey(const Key('input_glucose')), findsOneWidget);
    expect(find.byKey(const Key('input_carbs')), findsOneWidget);
    expect(find.byKey(const Key('btn_calculate')), findsOneWidget);
    expect(find.text('Calculadora'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Parâmetros'), findsOneWidget);

    // 2. Tenta calcular sem nenhum valor -> Mensagem de validação na tela
    await tester.tap(find.byKey(const Key('btn_calculate')));
    await tester.pumpAndSettle();
    expect(
      find.text('Informe a glicemia ou a quantidade de carboidratos.'),
      findsOneWidget,
    );

    // 3. Preenche glicemia (200) e carboidratos (40)
    await tester.enterText(find.byKey(const Key('input_glucose')), '200');
    await tester.enterText(find.byKey(const Key('input_carbs')), '40');
    await tester.pumpAndSettle();

    // 4. Executa o cálculo -> Abre a ResultScreen
    await tester.tap(find.byKey(const Key('btn_calculate')));
    await tester.pumpAndSettle();

    // 5. Verifica os componentes da ResultScreen
    expect(find.text('Resultado do Bolus'), findsOneWidget);
    expect(find.text('DOSE TOTAL RECOMENDADA'), findsOneWidget);
    expect(find.text('Composição da Dose'), findsOneWidget);
    expect(find.text('Detalhes do cálculo'), findsOneWidget);

    // 6. Rola até o widget e expande os detalhes do cálculo
    await tester.ensureVisible(find.text('Detalhes do cálculo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detalhes do cálculo'));
    await tester.pumpAndSettle();

    expect(find.text('1. Insulina para Carboidratos:'), findsOneWidget);
    expect(find.text('2. Correção da Glicemia:'), findsOneWidget);

    // 7. Retorna para a tela de cálculo pelo botão 'NOVO CÁLCULO'
    await tester.ensureVisible(find.byKey(const Key('btn_new_calculation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_new_calculation')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_calculate')), findsOneWidget);

    // 8. Testa navegação para a aba de Histórico
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de Cálculos'), findsOneWidget);

    // 9. Testa navegação para a aba de Parâmetros
    await tester.tap(find.text('Parâmetros'));
    await tester.pumpAndSettle();
    expect(find.text('Configurações de Insulina'), findsOneWidget);
  });
}
