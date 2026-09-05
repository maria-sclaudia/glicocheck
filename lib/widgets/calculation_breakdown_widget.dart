import 'package:flutter/material.dart';
import '../models/bolus_calculation_result.dart';

/// Seção expansível apresentando a conferência detalhada passo a passo dos cálculos.
class CalculationBreakdownWidget extends StatefulWidget {
  final BolusCalculationResult result;

  const CalculationBreakdownWidget({
    super.key,
    required this.result,
  });

  @override
  State<CalculationBreakdownWidget> createState() =>
      _CalculationBreakdownWidgetState();
}

class _CalculationBreakdownWidgetState
    extends State<CalculationBreakdownWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breakdown = widget.result.breakdown;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.functions_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Detalhes do cálculo',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _isExpanded ? 'Ocultar' : 'Conferir fórmulas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Carboidratos
                  _buildFormulaStep(
                    context,
                    title: '1. Insulina para Carboidratos:',
                    formula: breakdown.carbohydrateFormula,
                    result: breakdown.carbohydrateResultText,
                    icon: Icons.bakery_dining_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 14),

                  // 2. Correção de Glicemia
                  _buildFormulaStep(
                    context,
                    title: '2. Correção da Glicemia:',
                    formula: breakdown.correctionFormula,
                    result: breakdown.correctionResultText,
                    icon: Icons.water_drop_outlined,
                    iconColor: const Color(0xFF0284C7),
                    extraInfo: widget.result.currentGlucose != null
                        ? 'Alvo calculado: ${widget.result.targetGlucose.toInt()} mg/dL (ponto central entre ${widget.result.targetMin.toInt()} e ${widget.result.targetMax.toInt()} mg/dL)\nSensibilidade: ${widget.result.insulinSensitivity.toInt()} mg/dL/U'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // 3. Soma Total
                  _buildFormulaStep(
                    context,
                    title: '3. Total Matemático:',
                    formula: breakdown.totalFormula,
                    result: breakdown.totalResultText,
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: theme.colorScheme.primary,
                  ),

                  // 4. Ajuste de Incremento (se houver)
                  if (breakdown.roundingFormula.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              breakdown.roundingFormula,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormulaStep(
    BuildContext context, {
    required String title,
    required String formula,
    required String result,
    required IconData icon,
    required Color iconColor,
    String? extraInfo,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formula,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
              if (extraInfo != null) ...[
                const SizedBox(height: 6),
                Text(
                  extraInfo,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
