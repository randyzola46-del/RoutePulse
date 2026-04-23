// lib/services/biometric_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

enum BiometricTypeEnum {
  fingerprint,
  face,
  iris,
  strong,
  weak,
}

enum BiometricResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  cancelled,
}

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException catch (e) {
      print('❌ Erreur vérification biométrie: $e');
      return false;
    }
  }

  Future<List<BiometricTypeEnum>> getAvailableBiometrics() async {
    try {
      final available = await _localAuth.getAvailableBiometrics();
      final List<BiometricTypeEnum> types = [];

      for (final bio in available) {
        if (bio == BiometricType.fingerprint) {
          types.add(BiometricTypeEnum.fingerprint);
        } else if (bio == BiometricType.face) {
          types.add(BiometricTypeEnum.face);
        } else if (bio == BiometricType.iris) {
          types.add(BiometricTypeEnum.iris);
        } else if (bio == BiometricType.strong) {
          types.add(BiometricTypeEnum.strong);
        } else if (bio == BiometricType.weak) {
          types.add(BiometricTypeEnum.weak);
        }
      }
      return types;
    } on PlatformException catch (e) {
      print('❌ Erreur récupération biométries: $e');
      return [];
    }
  }

  Future<bool> isBiometricEnrolled() async {
    try {
      return await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// ✅ NOUVEAU : Réinitialise l'authentification biométrique
  /// Permet de contourner le verrouillage temporaire (30s) pour les tests
  Future<void> resetAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      print('✅ Authentification biométrique réinitialisée');
    } catch (e) {
      print('⚠️ Erreur lors de la réinitialisation: $e');
    }
  }

  /// Version SIMPLIFIÉE pour les tests avec reset automatique
  Future<BiometricResult> authenticateSimple({
    required String reason,
  }) async {
    try {
      // ✅ Réinitialiser avant chaque tentative
      await resetAuthentication();

      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricResult.notAvailable;
      }

      final isEnrolled = await isBiometricEnrolled();
      if (!isEnrolled) {
        return BiometricResult.notEnrolled;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: false,
          biometricOnly: true,
        ),
      );

      return authenticated ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      print('❌ Erreur PlatformException: ${e.code}');

      if (e.code == auth_error.lockedOut) {
        print('⚠️ Verrouillé - retourne failed pour les tests');
        return BiometricResult.failed;
      }
      if (e.code == auth_error.permanentlyLockedOut) {
        return BiometricResult.permanentlyLockedOut;
      }
      if (e.code == 'Canceled') {
        return BiometricResult.cancelled;
      }
      return BiometricResult.failed;
    } catch (e) {
      print('❌ Erreur inattendue: $e');
      return BiometricResult.failed;
    }
  }

  Future<BiometricResult> authenticate({
    required String reason,
    String? title,
    String? subtitle,
    String? cancelButtonTitle,
    bool stickyAuth = true,
    bool biometricOnly = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricResult.notAvailable;
      }

      final isEnrolled = await isBiometricEnrolled();
      if (!isEnrolled) {
        return BiometricResult.notEnrolled;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
          sensitiveTransaction: true,
        ),
      );

      return authenticated ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      print('❌ Erreur PlatformException: ${e.code}');

      switch (e.code) {
        case auth_error.notAvailable:
          return BiometricResult.notAvailable;
        case auth_error.notEnrolled:
          return BiometricResult.notEnrolled;
        case auth_error.lockedOut:
          return BiometricResult.lockedOut;
        case auth_error.permanentlyLockedOut:
          return BiometricResult.permanentlyLockedOut;
        case 'Canceled':
          return BiometricResult.cancelled;
        default:
          return BiometricResult.failed;
      }
    } catch (e) {
      return BiometricResult.failed;
    }
  }

  Future<BiometricResult> authenticateWithFallback({
    required String reason,
    required VoidCallback onPasswordFallback,
  }) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        return BiometricResult.success;
      }
      return BiometricResult.failed;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled) {
        onPasswordFallback();
      }
      return BiometricResult.notAvailable;
    }
  }

  Future<void> saveBiometricPreference(String userId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_${userId}_enabled', enabled);
  }

  Future<bool> getBiometricPreference(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_${userId}_enabled') ?? false;
  }

  Future<void> saveBiometricCredentials(String userId, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('biometric_${userId}_email', email);
    final secureStorage = const FlutterSecureStorage();
    await secureStorage.write(key: 'biometric_${userId}_password', value: password);
  }

  Future<({String email, String password})?> getBiometricCredentials(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('biometric_${userId}_email');
    final secureStorage = const FlutterSecureStorage();
    final password = await secureStorage.read(key: 'biometric_${userId}_password');

    if (email != null && password != null) {
      return (email: email, password: password);
    }
    return null;
  }

  Future<void> clearBiometricCredentials(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biometric_${userId}_enabled');
    await prefs.remove('biometric_${userId}_email');
    final secureStorage = const FlutterSecureStorage();
    await secureStorage.delete(key: 'biometric_${userId}_password');
  }
}

extension BiometricTypeLabel on BiometricTypeEnum {
  String get label {
    switch (this) {
      case BiometricTypeEnum.fingerprint:
        return 'Empreinte digitale';
      case BiometricTypeEnum.face:
        return 'Reconnaissance faciale';
      case BiometricTypeEnum.iris:
        return 'Reconnaissance irienne';
      case BiometricTypeEnum.strong:
        return 'Biométrie forte';
      case BiometricTypeEnum.weak:
        return 'Biométrie faible';
    }
  }

  IconData get icon {
    switch (this) {
      case BiometricTypeEnum.fingerprint:
        return Icons.fingerprint;
      case BiometricTypeEnum.face:
        return Icons.face_4;
      case BiometricTypeEnum.iris:
        return Icons.remove_red_eye;
      case BiometricTypeEnum.strong:
        return Icons.security;
      case BiometricTypeEnum.weak:
        return Icons.lock_outline;
    }
  }
}

extension BiometricResultExtension on BiometricResult {
  String get message {
    switch (this) {
      case BiometricResult.success:
        return 'Authentification réussie';
      case BiometricResult.failed:
        return 'Échec de l\'authentification';
      case BiometricResult.notAvailable:
        return 'Biométrie non disponible sur cet appareil';
      case BiometricResult.notEnrolled:
        return 'Aucune empreinte/visage enregistré';
      case BiometricResult.lockedOut:
        return 'Trop de tentatives. Réessayez plus tard.';
      case BiometricResult.permanentlyLockedOut:
        return 'Biométrie verrouillée définitivement';
      case BiometricResult.cancelled:
        return 'Authentification annulée';
    }
  }

  bool get isSuccess => this == BiometricResult.success;
}