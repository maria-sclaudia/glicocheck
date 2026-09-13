import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/time_block.dart';

/// Diálogo para criação e edição de um bloco de horário com configurações personalizadas de insulina.
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
    _labelController = TextEditingController(
      text: block?.label ?? 'Novo Bloco',
    );
    _targetMinController = TextEditingController(
      text: _formatNum(block?.targetMin ?? 80),
    );
    _targetMaxController = TextEditingController(
      text: _formatNum(block?.targetMax ?? 120),
    );
    _sensitivityController = TextEditingController(
      text: _formatNum(block?.insulinSensitivity ?? 50),
    );
    _ratioController = TextEditingController(
      text: _formatNum(block?.carbohydrateRatio ?? 12),
    );

    _startTime = block != null
        ? TimeOfDay(hour: block.startHour, minute: block.startMinute)
        : const TimeOfDay(hour: 6, minute: 0);
    _endTime = block != null
        ? TimeOfDay(hour: block.endHour, minute: block.endMinute)
        : const TimeOfDay(hour: 12, minute: 0);
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

  String _formatNum(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toString().replaceAll('.', ',');
  }

  double? _parseNum(String text) {
    final clean = text.trim().replaceAll(',', '.');
    return double.tryParse(clean);
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
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
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final targetMin = _parseNum(_targetMinController.text) ?? 80.0;
    final targetMax = _parseNum(_targetMaxController.text) ?? 120.0;
    final sensitivity = _parseNum(_sensitivityController.text) ?? 50.0;
    final ratio = _parseNum(_ratioController.text) ?? 12.0;

    final block = TimeBlock(
      id: widget.initialBlock?.id ??
          'block_${DateTime.now().millisecondsSinceEpoch}',
      label: _labelController.text.trim(),
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      targetMin: targetMin,
      targetMax: targetMax,
      insulinSensitivity: sensitivity,
      carbohydrateRatio: ratio,
    );

    Navigator.of(context).pop(block);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialBlock != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Bloco' : 'Novo Bloco de Horário'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Nome / Rótulo',
                  hintText: 'Ex: Manhã, Almoço, Noite',
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Informe um nome' : null,
              ),
              const SizedBox(height: 16),

              // Horários
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectStartTime,
                      child: Text(
                        'Início: ${_startTime.format(context)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectEndTime,
                      child: Text(
                        'Fim: ${_endTime.format(context)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Faixa-Alvo
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetMinController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Alvo Mín',
                        suffixText: 'mg/dL',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _targetMaxController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Alvo Máx',
                        suffixText: 'mg/dL',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Relação CHO
              TextFormField(
                controller: _ratioController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Relação Carboidrato (CHO)',
                  suffixText: 'g / 1 U',
                  hintText: 'Ex: 12',
                ),
              ),
              const SizedBox(height: 16),

              // Sensibilidade
              TextFormField(
                controller: _sensitivityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Fator de Sensibilidade (ISF)',
                  suffixText: 'mg/dL / 1 U',
                  hintText: 'Ex: 50',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
