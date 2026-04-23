// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/encryption_service.dart';
import 'services/app_database_service.dart';
import 'services/osrm_service.dart';
import 'theme/app_theme.dart';
import 'views/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Hive pour le cache géocodage
  await Hive.initFlutter();
  await GeocodingCache.init();

  // Initialisation SharedPreferences
  await SharedPreferences.getInstance();

  // Initialisation du chiffrement
  await EncryptionService().init();

  // Initialisation du service de base de données avec chiffrement
  await AppDatabaseService().init(useEncryption: true);

  runApp(
    const ProviderScope(
      child: RoutePulseApp(),
    ),
  );
}

class RoutePulseApp extends StatelessWidget {
  const RoutePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoutePulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthWrapper(),
    );
  }
}