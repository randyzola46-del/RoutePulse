// lib/services/auth_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';
  static const String _usersKey = 'registered_users';

  final Uuid _uuid = const Uuid();

  Future<List<User>> _getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    return usersJson
        .map((json) => User.fromMap(jsonDecode(json)))
        .toList();
  }

  Future<void> _saveRegisteredUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((u) => jsonEncode(u.toMap())).toList();
    await prefs.setStringList(_usersKey, usersJson);
  }

  Future<User?> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    String? phone,
  }) async {
    final users = await _getRegisteredUsers();
    if (users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      throw Exception('Cet email est déjà utilisé');
    }

    final newUser = User(
      id: _uuid.v4(),
      email: email.toLowerCase(),
      nom: nom.trim(),
      prenom: prenom.trim(),
      dateCreation: DateTime.now(),
      phone: phone,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pw_${newUser.id}', password);
    // ✅ AJOUT : Sauvegarder aussi pour la biométrie
    await prefs.setString('user_${newUser.id}_password', password);

    users.add(newUser);
    await _saveRegisteredUsers(users);
    await _saveSession(newUser);

    return newUser;
  }

  Future<User?> login(String email, String password) async {
    final users = await _getRegisteredUsers();
    final user = users.firstWhere(
          (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => throw Exception('Email ou mot de passe incorrect'),
    );

    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString('pw_${user.id}');

    if (storedPassword != password) {
      throw Exception('Email ou mot de passe incorrect');
    }

    // ✅ AJOUT : Sauvegarder le mot de passe pour la biométrie
    await prefs.setString('user_${user.id}_password', password);

    await _saveSession(user);
    return user;
  }

  /// ✅ NOUVEAU : Récupérer le mot de passe d'un utilisateur
  Future<String?> getUserPassword(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_${userId}_password');
  }

  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final token = _uuid.v4();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      return User.fromMap(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    return token != null && userJson != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<void> createDefaultUser() async {
    final users = await _getRegisteredUsers();
    if (users.isEmpty) {
      await register(
        email: 'demo@routepulse.com',
        password: 'demo123',
        nom: 'Dupont',
        prenom: 'Jean',
        phone: '+261 00 000 00',
      );
    }
  }
}