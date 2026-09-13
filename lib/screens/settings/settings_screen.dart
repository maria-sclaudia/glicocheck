import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/insulin_settings.dart';
import '../../models/time_block.dart';
import '../../services/settings_service.dart';
import 'widgets/time_block_editor_dialog.dart';

/// Tela de Configurações de Insulina, parâmetros clínicos e blocos de horário.
class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;
  final bool isTab;
  final VoidCallback? onNavigateBackToHome;

  const SettingsScreen({
    super.key,
    required this.settingsService,
    this.isTab = false,
    this.onNavigateBackToHome,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _targetMinController;
  late TextEditingController _targetMaxController;
  late TextEditingController _sensitivityController;
  late TextEditingController _ratioController;
  late TextEditingController _maxBolusController;

  late double _selectedIncrement;
  late bool _useTimeBlocks;
  late List<TimeBlock> _timeBlocks;

  @override
  void initState() {
    super.initState();
    _loadFromSettings(widget.settingsService.settings);
  }

  void _loadFromSettings(InsulinSettings s) {
    _targetMinController = TextEditingController(text: _formatNum(s.targetMin));
    _targetMaxController = TextEditingController(text: _formatNum(s.targetMax));
    _sensitivityController =
        TextEditingController(text: _formatNum(s.insulinSensitivity));
    _ratioController =
        TextEditingController(text: _formatNum(s.carbohydrateRatio));
    _maxBolusController = TextEditingController(text: _formatNum(s.maxBolus));

    _selectedIncrement = s.insulinIncrement;
    _useTimeBlocks = s.useTimeBlocks;
    _timeBlocks = List.from(s.timeBlocks);
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
    _targetMinController.dispose();
    _targetMaxController.dispose();
    _sensitivityController.dispose();
    _ratioController.dispose();
    _maxBolusController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final targetMin = _parseNum(_targetMinController.text) ?? 80.0;
    final targetMax = _parseNum(_targetMaxController.text) ?? 120.0;
    final sens = _parseNum(_sensitivityController.text) ?? 50.0;
    final ratio = _parseNum(_ratioController.text) ?? 12.0;
    final maxBolus = _parseNum(_maxBolusController.text) ?? 10.0;

    if (targetMin >= targetMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A glicemia alvo mínima deve ser menor que a máxima.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newSettings = InsulinSettings(
      targetMin: targetMin,
      targetMax: targetMax,
      insulinSensitivity: sens,
      carbohydrateRatio: ratio,
      insulinIncrement: _selectedIncrement,
      maxBolus: maxBolus,
      useTimeBlocks: _useTimeBlocks,
      timeBlocks: _timeBlocks,
    );

    await widget.settingsService.saveSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações salvas com sucesso!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (widget.onNavigateBackToHome != null) {
        widget.onNavigateBackToHome!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Padrões?'),
        content: const Text(
          'Deseja redefinir todas as configurações de insulina e blocos de horário para os valores recomendados iniciais?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.settingsService.resetToDefaults();
      setState(() {
        _loadFromSettings(widget.settingsService.settings);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações restauradas para o padrão.')),
        );
      }
    }
  }

  Future<void> _addTimeBlock() async {
    final newBlock = await TimeBlockEditorDialog.show(context);
    if (newBlock != null) {
      setState(() {
        _timeBlocks.add(newBlock);
      });
    }
  }

  Future<void> _editTimeBlock(int index) async {
    final block = _timeBlocks[index];
    final updated = await TimeBlockEditorDialog.show(
      context,
      initialBlock: block,
    );
    if (updated != null) {
      setState(() {
        _timeBlocks[index] = updated;
      });
    }
  }

  void _deleteTimeBlock(int index) {
    setState(() {
      _timeBlocks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isTab,
        title: const Text('Configurações de Insulina'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_rounded),
            tooltip: 'Restaurar Padrões',
            onPressed: _resetToDefaults,
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Salvar',
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Aviso de segurança pessoal
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Todos os parâmetros abaixo são salvos localmente e personalizáveis conforme prescrição médica.',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onPrimaryContainer,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. Faixa-Alvo Geral
              _buildSectionHeader(
                context,
                title: 'Faixa-Alvo de Glicemia',
                icon: Icons.track_changes_rounded,
                subtitle: 'Determina quando a correção deve ser calculada (ponto central será o alvo)',
              ),
              const SizedBox(height: 12),
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
                        hintText: 'Ex: 80',
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
                        hintText: 'Ex: 120',
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
              const SizedBox(height: 24),

              // 2. Sensibilidade e Relação Padrão
              _buildSectionHeader(
                context,
                title: 'Parâmetros Clínicos Padrão',
                icon: Icons.medical_services_outlined,
                subtitle: 'Fator de sensibilidade à insulina e relação carboidrato/insulina',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sensitivityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Sensibilidade',
                        suffixText: 'mg/dL/U',
                        hintText: 'Ex: 50',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Obrigatório';
                        final n = _parseNum(val);
                        if (n == null || n <= 0) return 'Deve ser > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ratioController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Relação Carbs',
                        suffixText: 'g/U',
                        hintText: 'Ex: 10',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Obrigatório';
                        final n = _parseNum(val);
                        if (n == null || n <= 0) return 'Deve ser > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Incremento e Limite Máximo
              _buildSectionHeader(
                context,
                title: 'Doses e Incremento',
                icon: Icons.tune_rounded,
                subtitle: 'Regra de arredondamento e limite máximo de segurança',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Incremento de Insulina (Passo)',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<double>(
                        segments: const [
                          ButtonSegment<double>(
                            value: 0.1,
                            label: Text('0,1 U'),
                          ),
                          ButtonSegment<double>(
                            value: 0.5,
                            label: Text('0,5 U'),
                          ),
                          ButtonSegment<double>(
                            value: 1.0,
                            label: Text('1,0 U'),
                          ),
                        ],
                        selected: {_selectedIncrement},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _selectedIncrement = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maxBolusController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d*')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Dose Máxima Permitida (Alerta de Segurança)',
                          suffixText: 'U',
                          hintText: 'Ex: 10',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Obrigatório';
                          final n = _parseNum(val);
                          if (n == null || n <= 0) return 'Deve ser > 0';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 4. Blocos de Horário
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildSectionHeader(
                      context,
                      title: 'Blocos de Horário',
                      icon: Icons.access_time_rounded,
                      subtitle: 'Parâmetros automáticos conforme a hora do dia',
                    ),
                  ),
                  Switch(
                    value: _useTimeBlocks,
                    onChanged: (val) {
                      setState(() {
                        _useTimeBlocks = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_useTimeBlocks) ...[
                if (_timeBlocks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Nenhum bloco cadastrado. Os parâmetros padrão serão utilizados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ...List.generate(_timeBlocks.length, (index) {
                    final block = _timeBlocks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.access_time_rounded,
                                      size: 18,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          block.timeRangeFormatted,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (block.label.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.secondaryContainer,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              block.label,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: theme.colorScheme.onSecondaryContainer,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    tooltip: 'Editar Bloco',
                                    onPressed: () => _editTimeBlock(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    tooltip: 'Excluir Bloco',
                                    color: Colors.red.shade400,
                                    onPressed: () => _deleteTimeBlock(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildParamChip(
                                    context,
                                    icon: Icons.gps_fixed_rounded,
                                    label: 'Faixa-alvo',
                                    value: block.targetRangeCompact(),
                                    color: const Color(0xFF0284C7),
                                  ),
                                  _buildParamChip(
                                    context,
                                    icon: Icons.bakery_dining_outlined,
                                    label: 'Relação Carbs',
                                    value: block.carbRatioFormatted,
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                  _buildParamChip(
                                    context,
                                    icon: Icons.water_drop_outlined,
                                    label: 'Sensibilidade',
                                    value: block.insulinSensitivityFormatted(),
                                    color: const Color(0xFF0D9488),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addTimeBlock,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar Bloco de Horário'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 36),

              // Botão Salvar
              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Salvar Todas as Configurações'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildParamChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
