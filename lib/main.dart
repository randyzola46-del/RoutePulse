import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'views/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
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
      home: const MainScaffold(),
    );
  }
}