import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../models/bolus_history_item.dart';
import '../../services/bolus_calculator_service.dart';
import '../../services/settings_service.dart';
import 'result_screen.dart';

/// Tela principal de Entrada e Cálculo Rápido de Bolus (Mobile-First).
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

  String? _validationError;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Atualiza relógio a cada 30s para manter o bloco ativo atualizado
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _glucoseController.dispose();
    _carbsController.dispose();
    _glucoseFocus.dispose();
    _carbsFocus.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  double? _parseInputValue(String text) {
    final clean = text.trim().replaceAll(',', '.');
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  void _addCarbs(int amount) {
    final current = _parseInputValue(_carbsController.text) ?? 0;
    final updated = (current + amount).toInt();
    setState(() {
      _carbsController.text = updated.toString();
    });
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
      });
      return;
    }

    try {
      final settings = widget.settingsService.settings;
      final result = widget.calculatorService.calculateBolus(
        glucose: glucose,
        carbohydrates: carbs,
        settings: settings,
        calculationTime: _currentTime,
      );

      setState(() {
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

      // Navegar para a Tela Dedicada de Resultado
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            result: result,
            settingsService: widget.settingsService,
          ),
        ),
      );
    } on BolusValidationException catch (e) {
      setState(() {
        _validationError = e.message;
      });
    } catch (e) {
      setState(() {
        _validationError = 'Erro ao realizar cálculo: $e';
      });
    }
  }

  void _onClear() {
    setState(() {
      _glucoseController.clear();
      _carbsController.clear();
      _validationError = null;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.settingsService.settings;
    final activeParams = settings.getActiveParameters(_currentTime);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Configurações',
            onPressed: widget.onNavigateToSettings ??
                () {
                  Navigator.pushNamed(context, '/settings');
                },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Bloco de Horário e Parâmetros Ativos (Compacto)
              _buildCompactActiveBanner(context, activeParams),
              const SizedBox(height: 16),

              // 2. Card de Entrada de Dados (Glicemia & Carboidratos)
              _buildInputCard(context),
              const SizedBox(height: 20),

              // 3. Mensagem de Validação de Erro
              if (_validationError != null) ...[
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
                const SizedBox(height: 20),
              ],

              // 4. Botão de Ação Principal: CALCULAR BOLUS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const Key('btn_calculate'),
                      onPressed: _onCalculate,
                      icon: const Icon(Icons.bolt_rounded, size: 24),
                      label: const Text(
                        'CALCULAR DOSE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 3,
                        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: _onClear,
                    tooltip: 'Limpar Campos',
                    icon: const Icon(Icons.refresh_rounded),
                    padding: const EdgeInsets.all(16),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Card Informativo de Dica de Uso Rápido
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Preencha a glicemia e/ou os carboidratos da refeição para calcular a recomendação exata de insulina.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner compacto com o período e parâmetros ativos
  Widget _buildCompactActiveBanner(BuildContext context, dynamic activeParams) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.schedule_rounded,
              size: 16,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      activeParams.sourceDescription,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Alvo: ${activeParams.targetRangeCompact()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Relação: ${activeParams.carbRatioFormatted}  •  Sensibilidade: ${activeParams.insulinSensitivityFormatted()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card ergonômico para entrada de dados
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
            const SizedBox(height: 12),

            // Atalhos rápidos de Carboidratos (+10g, +15g, +30g, +50g)
            Row(
              children: [
                _buildQuickCarbChip('+10g', 10),
                const SizedBox(width: 6),
                _buildQuickCarbChip('+15g', 15),
                const SizedBox(width: 6),
                _buildQuickCarbChip('+30g', 30),
                const SizedBox(width: 6),
                _buildQuickCarbChip('+50g', 50),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCarbChip(String label, int amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _addCarbs(amount),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
