import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_flow_mobile/locator.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/features/main/screens/main_screen.dart';
import 'package:music_flow_mobile/providers/local_library_provider.dart';
import 'package:music_flow_mobile/services/telemetry_service.dart';
import 'package:music_flow_mobile/core/app_theme.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  setupLocator();
  
  // Ініціалізація телеметрії помилок за згодою користувача
  TelemetryService.initGlobalCrashHandler();
  
  // Start background sync of local files on app startup
  locator<LocalLibraryProvider>().init();
  
  runApp(const MusicFlowApp());
}

class MusicFlowApp extends StatelessWidget {
  const MusicFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => VisualizerSettingsProvider()),
      ],
      child: MaterialApp(
        title: 'MusicFlow Mobile',
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
      ),
    );
  }
}
