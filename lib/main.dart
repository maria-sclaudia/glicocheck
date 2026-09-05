import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsService = SettingsService();
  await settingsService.init();

  runApp(GlicoBolusApp(settingsService: settingsService));
}

class GlicoBolusApp extends StatelessWidget {
  final SettingsService settingsService;

  const GlicoBolusApp({
    super.key,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsService,
      builder: (context, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          initialRoute: AppRoutes.home,
          onGenerateRoute: (settings) =>
              AppRoutes.generateRoute(settings, settingsService),
        );
      },
    );
  }
}
