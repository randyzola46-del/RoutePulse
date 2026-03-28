import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:route_pulse/views/livraisons_list_view.dart';
import 'theme/app_theme.dart';

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
