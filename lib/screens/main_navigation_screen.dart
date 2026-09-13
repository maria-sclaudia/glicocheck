import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'calculator/calculator_screen.dart';
import 'history/history_screen.dart';
import 'settings/settings_screen.dart';

/// Tela principal com barra de navegação inferior (Bottom Navigation) ideal para celular.
class MainNavigationScreen extends StatefulWidget {
  final SettingsService settingsService;
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    required this.settingsService,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final screens = [
      CalculatorScreen(
        settingsService: widget.settingsService,
        onNavigateToHistory: () => _onTabSelected(1),
        onNavigateToSettings: () => _onTabSelected(2),
      ),
      HistoryScreen(
        settingsService: widget.settingsService,
        isTab: true,
      ),
      SettingsScreen(
        settingsService: widget.settingsService,
        isTab: true,
        onNavigateBackToHome: () => _onTabSelected(0),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        elevation: 8,
        indicatorColor: theme.colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate_rounded),
            label: 'Calculadora',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Parâmetros',
          ),
        ],
      ),
    );
  }
}
