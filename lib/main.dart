import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'locator.dart';
import 'providers/audio_provider.dart';
import 'providers/visualizer_settings_provider.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  setupLocator();
  
  // Register the AudioProvider and initialize audio_service there, 
  // or we can initialize it directly in AudioProvider constructor to keep it clean.
  
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
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFFE53935), // Red Accent
          scaffoldBackgroundColor: const Color(0xFF161616), // Dark background
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF161616),
            elevation: 0,
            centerTitle: true,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1E1E1E),
            selectedItemColor: Color(0xFFE53935),
            unselectedItemColor: Colors.grey,
            elevation: 8,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
          ),
          cardColor: const Color(0xFF212121),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE53935),
            secondary: Color(0xFFE53935),
            surface: Color(0xFF212121),
          ),
          fontFamily: 'Inter',
        ),
        home: const MainScreen(),
      ),
    );
  }
}
