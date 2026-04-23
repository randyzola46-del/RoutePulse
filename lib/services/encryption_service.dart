// lib/services/encryption_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Service de chiffrement pour les données sensibles
/// Utilise AES-256-GCM pour le chiffrement des données SQLite
/// et flutter_secure_storage pour la clé maître
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const String _masterKeyId = 'routepulse_master_key';
  static const String _ivKeyId = 'routepulse_iv';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  encrypt.Key? _masterKey;
  encrypt.IV? _iv;

  bool get isInitialized => _masterKey != null && _iv != null;

  /// Initialise ou récupère la clé de chiffrement maître
  Future<void> init() async {
    // Récupérer la clé existante ou en créer une nouvelle
    final storedKey = await _secureStorage.read(key: _masterKeyId);
    final storedIv = await _secureStorage.read(key: _ivKeyId);

    if (storedKey != null && storedIv != null) {
      // Décoder la clé et l'IV existants
      _masterKey = encrypt.Key.fromBase64(storedKey);
      _iv = encrypt.IV.fromBase64(storedIv);
      print('✅ Clé de chiffrement chargée');
    } else {
      // Générer une nouvelle clé AES-256 et un nouvel IV
      _masterKey = encrypt.Key.fromSecureRandom(32);
      _iv = encrypt.IV.fromSecureRandom(16);
      await _secureStorage.write(key: _masterKeyId, value: _masterKey!.base64);
      await _secureStorage.write(key: _ivKeyId, value: _iv!.base64);
      print('✅ Nouvelle clé de chiffrement générée');
    }
  }

  /// Chiffre une chaîne de caractères
  String encryptString(String plainText) {
    if (!isInitialized) {
      throw StateError('EncryptionService non initialisé. Appelez init() d\'abord.');
    }
    if (plainText.isEmpty) return '';

    try {
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_masterKey!, mode: encrypt.AESMode.gcm),
      );
      final encrypted = encrypter.encrypt(plainText, iv: _iv!);
      return encrypted.base64;
    } catch (e) {
      print('❌ Erreur chiffrement: $e');
      return plainText;
    }
  }

  /// Déchiffre une chaîne de caractères
  String decryptString(String encryptedBase64) {
    if (!isInitialized) {
      throw StateError('EncryptionService non initialisé. Appelez init() d\'abord.');
    }
    if (encryptedBase64.isEmpty) return '';

    try {
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_masterKey!, mode: encrypt.AESMode.gcm),
      );
      final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
      return encrypter.decrypt(encrypted, iv: _iv!);
    } catch (e) {
      // Si le déchiffrement échoue, c'est peut-être une donnée non chiffrée
      print('⚠️ Échec déchiffrement (donnée probablement non chiffrée): $e');
      return encryptedBase64;
    }
  }

  /// Chiffre un Map pour stockage SQLite
  Map<String, dynamic> encryptMap(Map<String, dynamic> data, List<String> sensitiveFields) {
    final encrypted = Map<String, dynamic>.from(data);

    for (final field in sensitiveFields) {
      if (encrypted.containsKey(field) && encrypted[field] != null) {
        final value = encrypted[field].toString();
        if (value.isNotEmpty) {
          encrypted[field] = encryptString(value);
        }
      }
    }

    return encrypted;
  }

  /// Déchiffre un Map provenant de SQLite
  Map<String, dynamic> decryptMap(Map<String, dynamic> data, List<String> sensitiveFields) {
    final decrypted = Map<String, dynamic>.from(data);

    for (final field in sensitiveFields) {
      if (decrypted.containsKey(field) && decrypted[field] != null) {
        final value = decrypted[field].toString();
        if (value.isNotEmpty) {
          try {
            decrypted[field] = decryptString(value);
          } catch (e) {
            print('⚠️ Champ non déchiffrable: $field');
          }
        }
      }
    }

    return decrypted;
  }

  /// Efface la clé maître (déconnexion)
  Future<void> clearMasterKey() async {
    await _secureStorage.delete(key: _masterKeyId);
    await _secureStorage.delete(key: _ivKeyId);
    _masterKey = null;
    _iv = null;
  }
}