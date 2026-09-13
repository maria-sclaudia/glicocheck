import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bolus_calculation_result.dart';
import '../../services/settings_service.dart';
import '../../widgets/calculation_breakdown_widget.dart';
import '../../widgets/glucose_status_badge.dart';
import '../history/history_screen.dart';

/// Tela dedicada para apresentação limpa e detalhada do resultado do Bolus.
class ResultScreen extends StatelessWidget {
  final BolusCalculationResult result;
  final SettingsService settingsService;
  final VoidCallback? onNewCalculation;
  final VoidCallback? onNavigateToHistory;
  final bool isTab;

  const ResultScreen({
    super.key,
    required this.result,
    required this.settingsService,
    this.onNewCalculation,
    this.onNavigateToHistory,
    this.isTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isTab,
        leading: isTab
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Voltar ao Formulário',
                onPressed: onNewCalculation,
              )
            : null,
        title: const Text(
          'Resultado do Bolus',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Alerta de Dose Máxima Ultrapassada (se aplicável)
              if (result.isMaxBolusExceeded) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade300, width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ATENÇÃO: Dose Máxima Ultrapassada!',
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'O total calculado (${BolusCalculationResult.formatUnits(result.totalInsulin)} U) ultrapassa o limite de segurança configurado (${BolusCalculationResult.formatUnits(result.maxBolus)} U).',
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Card Hero do Total Recomendado
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            result.configurationUsed,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medication_liquid_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'DOSE TOTAL RECOMENDADA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${BolusCalculationResult.formatUnits(result.totalInsulin)} U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unidades de Insulina Rápida',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Status Glicêmico (se glicemia informada)
              if (result.currentGlucose != null) ...[
                GlucoseStatusBadge(
                  glucose: result.currentGlucose!,
                  targetMin: result.targetMin,
                  targetMax: result.targetMax,
                ),
                const SizedBox(height: 16),
              ],

              // Card de Componentes da Dose (Carboidratos vs Correção)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Composição da Dose',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // Componente Carboidratos
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
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
                                        size: 16,
                                        color: Color(0xFF8B5CF6),
                                      ),
                                      SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Carboidratos',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${BolusCalculationResult.formatUnits(result.carbohydrateInsulin)} U',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF6D28D9),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    result.carbohydrates != null
                                        ? '${result.carbohydrates!.toInt()} g (1U/${result.carbohydrateRatio.toInt()}g)'
                                        : '0 g informados',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Componente Correção
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
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
                                        size: 16,
                                        color: Color(0xFF0284C7),
                                      ),
                                      SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Correção',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0284C7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${BolusCalculationResult.formatUnits(result.correctionInsulin)} U',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0369A1),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    result.currentGlucose != null
                                        ? '${result.currentGlucose!.toInt()} mg/dL (Alvo ${result.targetGlucose.toInt()})'
                                        : 'Não informada',
                                    style: TextStyle(
                                      fontSize: 11,
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
              const SizedBox(height: 16),

              // Memória e Detalhes do Cálculo (Fórmula)
              CalculationBreakdownWidget(result: result),
              const SizedBox(height: 24),

              // Botão de Retorno / Novo Cálculo
              ElevatedButton.icon(
                key: const Key('btn_new_calculation'),
                onPressed: () {
                  if (onNewCalculation != null) {
                    onNewCalculation!();
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: const Text(
                  'NOVO CÁLCULO',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  if (onNavigateToHistory != null) {
                    onNavigateToHistory!();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryScreen(settingsService: settingsService),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.history_rounded, size: 20),
                label: const Text(
                  'Visualizar Histórico Completo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
