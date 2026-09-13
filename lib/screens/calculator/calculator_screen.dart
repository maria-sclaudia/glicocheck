import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bolus_calculation_result.dart';
import '../../models/bolus_history_item.dart';
import '../../services/bolus_calculator_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/calculation_breakdown_widget.dart';
import '../../widgets/glucose_status_badge.dart';

/// Tela unificada de Entrada e Resultado de Bolus de Insulina (Mobile-First).
class CalculatorScreen extends StatefulWidget {
  final SettingsService settingsService;
  final BolusCalculatorService calculatorService;
  final VoidCallback? onNavigateToHistory;
  final VoidCallback? onNavigateToSettings;

  const CalculatorScreen({
    super.key,
    required this.settingsService,
    this.calculatorService = const BolusCalculatorService(),
    this.onNavigateToHistory,
    this.onNavigateToSettings,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();

  final FocusNode _glucoseFocus = FocusNode();
  final FocusNode _carbsFocus = FocusNode();

  BolusCalculationResult? _lastResult;
  String? _validationError;

  @override
  void dispose() {
    _glucoseController.dispose();
    _carbsController.dispose();
    _glucoseFocus.dispose();
    _carbsFocus.dispose();
    super.dispose();
  }

  double? _parseInputValue(String text) {
    final clean = text.trim().replaceAll(',', '.');
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  void _onCalculate() {
    setState(() {
      _validationError = null;
    });

    final glucose = _parseInputValue(_glucoseController.text);
    final carbs = _parseInputValue(_carbsController.text);

    // Validação inicial
    if (glucose == null && carbs == null) {
      setState(() {
        _validationError = 'Informe a glicemia ou a quantidade de carboidratos.';
        _lastResult = null;
      });
      return;
    }

    try {
      final settings = widget.settingsService.settings;
      final result = widget.calculatorService.calculateBolus(
        glucose: glucose,
        carbohydrates: carbs,
        settings: settings,
        calculationTime: DateTime.now(),
      );

      setState(() {
        _lastResult = result;
        _validationError = null;
      });

      // Fechar teclado
      FocusScope.of(context).unfocus();

      // Salvar automaticamente no histórico
      final historyItem = BolusHistoryItem(
        id: 'calc_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        glucose: result.currentGlucose,
        carbohydrates: result.carbohydrates,
        carbohydrateInsulin: result.carbohydrateInsulin,
        correctionInsulin: result.correctionInsulin,
        totalInsulin: result.totalInsulin,
        configurationUsed: result.configurationUsed,
        targetMin: result.targetMin,
        targetMax: result.targetMax,
        insulinSensitivity: result.insulinSensitivity,
        carbohydrateRatio: result.carbohydrateRatio,
      );
      widget.settingsService.addHistoryItem(historyItem);
    } on BolusValidationException catch (e) {
      setState(() {
        _validationError = e.message;
        _lastResult = null;
      });
    } catch (e) {
      setState(() {
        _validationError = 'Erro ao realizar cálculo: $e';
        _lastResult = null;
      });
    }
  }

  void _onClear() {
    setState(() {
      _glucoseController.clear();
      _carbsController.clear();
      _lastResult = null;
      _validationError = null;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calculate_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                Text(
                  'Calculadora de Bolus',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Card de Entrada de Dados (Glicemia & Carboidratos)
              _buildInputCard(context),
              const SizedBox(height: 16),

              // 2. Botão de Ação: CALCULAR DOSE e Limpar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const Key('btn_calculate'),
                      onPressed: _onCalculate,
                      icon: const Icon(Icons.bolt_rounded, size: 22),
                      label: const Text(
                        'CALCULAR DOSE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: _onClear,
                    tooltip: 'Limpar Campos',
                    icon: const Icon(Icons.refresh_rounded),
                    padding: const EdgeInsets.all(15),
                  ),
                ],
              ),

              // 3. Mensagem de Validação de Erro
              if (_validationError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 4. Seção Unificada do Resultado da Dose (Apresentação Discreta e Completa)
              if (_lastResult != null) ...[
                const SizedBox(height: 20),
                _buildDiscreetResultSection(context, _lastResult!),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Card de entrada de dados (Glicemia & Carboidratos)
  Widget _buildInputCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo Glicemia Atual
            Row(
              children: [
                const Icon(
                  Icons.water_drop_rounded,
                  size: 18,
                  color: Color(0xFF0284C7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Glicemia Atual',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('input_glucose'),
              controller: _glucoseController,
              focusNode: _glucoseFocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
              ],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Ex: 140',
                suffixText: 'mg/dL',
                suffixStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.speed_rounded, color: Color(0xFF0284C7)),
                suffixIcon: _glucoseController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _glucoseController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _carbsFocus.requestFocus(),
            ),
            const SizedBox(height: 20),

            // Campo Carboidratos
            Row(
              children: [
                const Icon(
                  Icons.bakery_dining_rounded,
                  size: 18,
                  color: Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Carboidratos da Refeição',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('input_carbs'),
              controller: _carbsController,
              focusNode: _carbsFocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
              ],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Ex: 45',
                suffixText: 'g',
                suffixStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.restaurant_rounded, color: Color(0xFF8B5CF6)),
                suffixIcon: _carbsController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _carbsController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _onCalculate(),
            ),
          ],
        ),
      ),
    );
  }

  /// Apresentação discreta e completa do resultado logo abaixo dos dados da refeição
  Widget _buildDiscreetResultSection(
    BuildContext context,
    BolusCalculationResult result,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Alerta de Dose Máxima Ultrapassada (se aplicável)
        if (result.isMaxBolusExceeded) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade300, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ATENÇÃO: Dose Máxima Ultrapassada!',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total calculado (${BolusCalculationResult.formatUnits(result.totalInsulin)} U) ultrapassa o limite (${BolusCalculationResult.formatUnits(result.maxBolus)} U).',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Card Discreto e Elegante com a Dose Recomendada
        Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Topo com Dose Recomendada
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOSE RECOMENDADA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${BolusCalculationResult.formatUnits(result.totalInsulin)} U',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'insulina rápida',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Status da Glicemia se informada
                if (result.currentGlucose != null) ...[
                  const SizedBox(height: 12),
                  GlucoseStatusBadge(
                    glucose: result.currentGlucose!,
                    targetMin: result.targetMin,
                    targetMax: result.targetMax,
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Composição da Dose (Carboidratos vs Correção)
                Text(
                  'Composição da Dose',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Carboidratos
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.bakery_dining_rounded,
                                  size: 15,
                                  color: Color(0xFF8B5CF6),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Carboidratos',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${BolusCalculationResult.formatUnits(result.carbohydrateInsulin)} U',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              result.carbohydrates != null
                                  ? '${result.carbohydrates!.toInt()} g (1U/${result.carbohydrateRatio.toInt()}g)'
                                  : '0 g',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Correção
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.water_drop_rounded,
                                  size: 15,
                                  color: Color(0xFF0284C7),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Correção',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${BolusCalculationResult.formatUnits(result.correctionInsulin)} U',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              result.currentGlucose != null
                                  ? '${result.currentGlucose!.toInt()} mg/dL'
                                  : 'Não informada',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Detalhes do Cálculo (Fórmulas Clínicas Retráteis)
        CalculationBreakdownWidget(result: result),
      ],
    );
  }
}
