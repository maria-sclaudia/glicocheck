import 'package:flutter/material.dart';
import '../../models/bolus_calculation_result.dart';
import '../../screens/calculator/result_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/main_navigation_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../services/settings_service.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String settings = '/settings';
  static const String history = '/history';
  static const String result = '/result';

  static Route<dynamic> generateRoute(
    RouteSettings routeSettings,
    SettingsService settingsService,
  ) {
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => MainNavigationScreen(settingsService: settingsService),
          settings: routeSettings,
        );
      case settings:
        return MaterialPageRoute(
          builder: (_) => SettingsScreen(settingsService: settingsService),
          settings: routeSettings,
        );
      case history:
        return MaterialPageRoute(
          builder: (_) => HistoryScreen(settingsService: settingsService),
          settings: routeSettings,
        );
      case result:
        final calcResult = routeSettings.arguments as BolusCalculationResult;
        return MaterialPageRoute(
          builder: (_) => ResultScreen(
            result: calcResult,
            settingsService: settingsService,
          ),
          settings: routeSettings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Não Encontrado'),
            ),
            body: Center(
              child: Text('Rota não definida: ${routeSettings.name}'),
            ),
          ),
          settings: routeSettings,
        );
    }
  }
}
