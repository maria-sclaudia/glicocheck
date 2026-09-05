import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Badge visual indicando o status da glicemia em relação à faixa-alvo.
class GlucoseStatusBadge extends StatelessWidget {
  final double glucose;
  final double targetMin;
  final double targetMax;

  const GlucoseStatusBadge({
    super.key,
    required this.glucose,
    required this.targetMin,
    required this.targetMax,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLow = glucose < targetMin;
    final bool isHigh = glucose > targetMax;

    final Color badgeColor;
    final Color textColor;
    final IconData icon;
    final String label;

    if (isLow) {
      badgeColor = AppTheme.glucoseLow.withValues(alpha: 0.15);
      textColor = AppTheme.glucoseLow;
      icon = Icons.warning_amber_rounded;
      label = 'Abaixo da faixa-alvo (< ${targetMin.toInt()} mg/dL)';
    } else if (isHigh) {
      badgeColor = AppTheme.glucoseHigh.withValues(alpha: 0.15);
      textColor = const Color(0xFFD97706);
      icon = Icons.arrow_upward_rounded;
      label = 'Acima da faixa-alvo (> ${targetMax.toInt()} mg/dL)';
    } else {
      badgeColor = AppTheme.glucoseNormal.withValues(alpha: 0.15);
      textColor = AppTheme.glucoseNormal;
      icon = Icons.check_circle_outline_rounded;
      label = 'Dentro da faixa-alvo (${targetMin.toInt()}–${targetMax.toInt()} mg/dL)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
