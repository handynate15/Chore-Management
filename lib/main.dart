import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize timezone data
  if (!kIsWeb) {
    tz.initializeTimeZones();
  }

  // Initialize notification service
  if (!kIsWeb) {
    await NotificationService().initialize();
  }

  final provider = AppProvider();
  await provider.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const OnTrackApp(),
    ),
  );
}

class OnTrackApp extends StatelessWidget {
  const OnTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
