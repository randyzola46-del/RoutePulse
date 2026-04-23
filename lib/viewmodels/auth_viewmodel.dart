// lib/viewmodels/auth_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/app_database_service.dart';
import 'livraisons_viewmodel.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  final Ref? _ref;

  AuthViewModel([this._ref]) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    await _authService.createDefaultUser();
    await checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        //Utilisation de AppDatabaseService
        AppDatabaseService().setCurrentUserId(user.id);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        return;
      }
    }
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        //Utilisation de AppDatabaseService
        await AppDatabaseService().resetDatabase();
        AppDatabaseService().setCurrentUserId(user.id);

        if (_ref != null) {
          await _ref!.read(livraisonsViewModelProvider.notifier).refresh();
        }

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        return true;
      }
      throw Exception('Erreur de connexion');
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final user = await _authService.register(
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
        phone: phone,
      );
      if (user != null) {
        //Utilisation de AppDatabaseService
        AppDatabaseService().setCurrentUserId(user.id);

        if (_ref != null) {
          await _ref!.read(livraisonsViewModelProvider.notifier).refresh();
        }

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        return true;
      }
      throw Exception('Erreur d\'inscription');
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    //Utilisation de AppDatabaseService
    await AppDatabaseService().resetDatabase();
    await _authService.logout();
    AppDatabaseService().clearCurrentUser();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
      (ref) => AuthViewModel(ref),
);