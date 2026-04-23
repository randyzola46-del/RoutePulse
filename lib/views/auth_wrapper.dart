// lib/views/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';
import 'main_scaffold.dart';
import 'onboarding_view.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _showOnboarding = true; // Toujours true au départ

  @override
  Widget build(BuildContext context) {
    // ✅ Toujours afficher l'onboarding d'abord
    if (_showOnboarding) {
      return OnboardingView(
        onDone: () => setState(() => _showOnboarding = false),
      );
    }

    // Après l'onboarding → flux d'auth normal
    final authState = ref.watch(authViewModelProvider);

    if (authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrincipal,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.coral),
        ),
      );
    }

    if (authState.status == AuthStatus.unauthenticated) {
      return const LoginView();
    }

    return const MainScaffold();
  }
}