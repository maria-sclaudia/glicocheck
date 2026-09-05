import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/time_block.dart';

/// Diálogo modal para criação ou edição de um bloco de horário.
class TimeBlockEditorDialog extends StatefulWidget {
  final TimeBlock? initialBlock;

  const TimeBlockEditorDialog({
    super.key,
    this.initialBlock,
  });

  static Future<TimeBlock?> show(
    BuildContext context, {
    TimeBlock? initialBlock,
  }) {
    return showDialog<TimeBlock>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TimeBlockEditorDialog(initialBlock: initialBlock),
    );
  }

  @override
  State<TimeBlockEditorDialog> createState() => _TimeBlockEditorDialogState();
}

class _TimeBlockEditorDialogState extends State<TimeBlockEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _labelController;
  late TextEditingController _targetMinController;
  late TextEditingController _targetMaxController;
  late TextEditingController _sensitivityController;
  late TextEditingController _ratioController;

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final block = widget.initialBlock;

    _labelController = TextEditingController(text: block?.label ?? '');
    _targetMinController = TextEditingController(
      text: block != null ? _formatNum(block.targetMin) : '80',
    );
    _targetMaxController = TextEditingController(
      text: block != null ? _formatNum(block.targetMax) : '120',
    );
    _sensitivityController = TextEditingController(
      text: block != null ? _formatNum(block.insulinSensitivity) : '50',
    );
    _ratioController = TextEditingController(
      text: block != null ? _formatNum(block.carbohydrateRatio) : '12',
    );

    _startTime = block != null
        ? TimeOfDay(hour: block.startHour, minute: block.startMinute)
        : const TimeOfDay(hour: 6, minute: 0);

    _endTime = block != null
        ? TimeOfDay(hour: block.endHour, minute: block.endMinute)
        : const TimeOfDay(hour: 12, minute: 0);
  }

  String _formatNum(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toString().replaceAll('.', ',');
  }

  double? _parseNum(String text) {
    final cleaned = text.trim().replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _targetMinController.dispose();
    _targetMaxController.dispose();
    _sensitivityController.dispose();
    _ratioController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'SELECIONAR HORÁRIO INICIAL',
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: 'SELECIONAR HORÁRIO FINAL',
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final targetMin = _parseNum(_targetMinController.text) ?? 80.0;
    final targetMax = _parseNum(_targetMaxController.text) ?? 120.0;
    final sens = _parseNum(_sensitivityController.text) ?? 50.0;
    final ratio = _parseNum(_ratioController.text) ?? 12.0;

    if (targetMin >= targetMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A glicemia alvo mínima deve ser menor que a máxima.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final id = widget.initialBlock?.id ??
        'block_${DateTime.now().millisecondsSinceEpoch}';

    final updatedBlock = TimeBlock(
      id: id,
      label: _labelController.text.trim(),
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      targetMin: targetMin,
      targetMax: targetMax,
      insulinSensitivity: sens,
      carbohydrateRatio: ratio,
    );

    Navigator.of(context).pop(updatedBlock);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialBlock != null;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.access_time_filled_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Editar Bloco de Horário' : 'Novo Bloco de Horário',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Parâmetros específicos para o período',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nome do Bloco
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Identificação do Bloco (Opcional)',
                    hintText: 'Ex: Café da Manhã, Almoço, Madrugada',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),

                // Intervalo de Horário
                Text(
                  'Intervalo de Horário',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectStartTime,
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text('Início: ${_formatTimeOfDay(_startTime)}'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectEndTime,
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text('Fim: ${_formatTimeOfDay(_endTime)}'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Faixa Alvo
                Row(
                  children: [
                    const Icon(Icons.gps_fixed_rounded, size: 16, color: Color(0xFF0284C7)),
                    const SizedBox(width: 6),
                    Text(
                      'Faixa-Alvo de Glicemia',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Faixa desejada de glicose durante este bloco (ex: 80 mg/dL - 120 mg/dL)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _targetMinController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Alvo Mínimo',
                          suffixText: 'mg/dL',
                          hintText: '80',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Obrigatório';
                          final n = _parseNum(val);
                          if (n == null || n <= 0) return 'Inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _targetMaxController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Alvo Máximo',
                          suffixText: 'mg/dL',
                          hintText: '120',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Obrigatório';
                          final n = _parseNum(val);
                          if (n == null || n <= 0) return 'Inválido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Relação Insulina / Carboidratos
                Row(
                  children: [
                    const Icon(Icons.bakery_dining_outlined, size: 16, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 6),
                    Text(
                      'Relação Insulina / Carboidratos',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Gramas de carboidrato cobertos por 1 Unidade de insulina (ex: 1 U p/ 12g)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ratioController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Relação Insulina/Carboidratos',
                    suffixText: 'g/U',
                    helperText: 'Ex: 12 (significa 1 U p/ 12g)',
                    prefixIcon: Icon(Icons.bakery_dining_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Obrigatório';
                    final n = _parseNum(val);
                    if (n == null || n <= 0) return '> 0';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Sensibilidade à Insulina
                Row(
                  children: [
                    const Icon(Icons.water_drop_outlined, size: 16, color: Color(0xFF0284C7)),
                    const SizedBox(width: 6),
                    Text(
                      'Sensibilidade à Insulina (Fator de Correção)',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Redução estimada de glicose no sangue por 1 Unidade de insulina (ex: 1 U p/ 50 mg/dL)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sensitivityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Sensibilidade à Insulina',
                    suffixText: 'mg/dL/U',
                    helperText: 'Ex: 50 (significa 1 U p/ 50 mg/dL)',
                    prefixIcon: Icon(Icons.water_drop_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Obrigatório';
                    final n = _parseNum(val);
                    if (n == null || n <= 0) return '> 0';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Ações
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _onSave,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(isEditing ? 'Salvar Alterações' : 'Adicionar Bloco'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
