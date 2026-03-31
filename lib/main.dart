import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'views/livraisons_list_view.dart';

void main() {
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
      home: const LivraisonsListView(),
    );
  }
}
