import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bolus_history_item.dart';
import '../models/insulin_settings.dart';

/// Serviço responsável por gerenciar e persistir as configurações de insulina e o histórico.
class SettingsService extends ChangeNotifier {
  static const String _settingsKey = 'glicobolus_insulin_settings_v2';
  static const String _historyKey = 'glicobolus_bolus_history_v1';
  static const int _maxHistoryItems = 100;

  InsulinSettings _settings = InsulinSettings.initialDefault();
  List<BolusHistoryItem> _history = [];
  bool _isInitialized = false;

  InsulinSettings get settings => _settings;
  List<BolusHistoryItem> get history => List.unmodifiable(_history);
  bool get isInitialized => _isInitialized;

  /// Inicializa o serviço carregando os dados do SharedPreferences
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Carregar configurações
      final settingsString = prefs.getString(_settingsKey);
      if (settingsString != null && settingsString.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(settingsString);
        _settings = InsulinSettings.fromJson(json);
      } else {
        _settings = InsulinSettings.initialDefault();
      }

      // Carregar histórico
      final historyString = prefs.getString(_historyKey);
      if (historyString != null && historyString.isNotEmpty) {
        final List<dynamic> list = jsonDecode(historyString);
        _history = list
            .map((item) => BolusHistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _history = [];
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do SettingsService: $e');
      _settings = InsulinSettings.initialDefault();
      _history = [];
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Salva novas configurações no SharedPreferences
  Future<void> saveSettings(InsulinSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(newSettings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('Erro ao persistir configurações: $e');
    }
  }

  /// Restaura as configurações padrão recomendadas
  Future<void> resetToDefaults() async {
    final defaults = InsulinSettings.initialDefault();
    await saveSettings(defaults);
  }

  /// Adiciona um novo registro ao histórico
  Future<void> addHistoryItem(BolusHistoryItem item) async {
    _history.insert(0, item);
    if (_history.length > _maxHistoryItems) {
      _history = _history.sublist(0, _maxHistoryItems);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(_history.map((h) => h.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      debugPrint('Erro ao persistir histórico: $e');
    }
  }

  /// Remove um item específico do histórico
  Future<void> deleteHistoryItem(String id) async {
    _history.removeWhere((item) => item.id == id);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(_history.map((h) => h.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      debugPrint('Erro ao remover item do histórico: $e');
    }
  }

  /// Limpa todo o histórico de cálculos
  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      debugPrint('Erro ao limpar histórico: $e');
    }
  }
}
