import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/client_provider.dart';
import 'providers/preferences_provider.dart';
import 'providers/task_provider.dart';
import 'screens/main_scaffold.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await NotificationService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const AtlasApp(),
    ),
  );
}

class AtlasApp extends StatelessWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();

    return MaterialApp(
      title: 'Atlas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: prefs.themeMode,
      home: const MainScaffold(),
    );
  }
}
