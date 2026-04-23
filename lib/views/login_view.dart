// lib/views/login_view.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/biometric_service.dart';
import '../widgets/biometric_auth_dialog.dart';
import 'register_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;

  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricStatus() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final savedEmail = await _getSavedEmail();
    setState(() => _isBiometricAvailable = isAvailable);
    if (savedEmail != null) _emailCtrl.text = savedEmail;
  }

  Future<String?> _getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_biometric_email');
  }

  Future<void> _saveLastEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_biometric_email', email);
  }

  Future<String?> _getUserIdFromEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('registered_users') ?? [];
    for (final json in usersJson) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(json);
        final user = User.fromMap(userMap);
        if (user.email.toLowerCase() == email.toLowerCase()) return user.id;
      } catch (e) {
        debugPrint('Erreur parsing user: $e');
      }
    }
    return null;
  }

  void _showBiometricDialog() {
    if (!_isBiometricAvailable || !mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BiometricAuthDialog(
        email: _emailCtrl.text,
        onSuccess: () async {
          if (!mounted) return;
          final userId = await _getUserIdFromEmail(_emailCtrl.text);
          if (userId != null) {
            final credentials = await _biometricService.getBiometricCredentials(userId);
            if (credentials != null) {
              await _handleLogin(credentials.email, credentials.password);
            }
          }
        },
        onUsePassword: () {
          if (!mounted) return;
          FocusScope.of(context).requestFocus(_passwordFocusNode);
        },
      ),
    );
  }

  Future<void> _handleLogin(String email, String password) async {
    setState(() => _isLoading = true);
    final success = await ref.read(authViewModelProvider.notifier).login(
      email.trim(),
      password,
    );
    setState(() => _isLoading = false);
    if (success && mounted) {
      await _saveLastEmail(email.trim());
    } else if (mounted) {
      final error = ref.read(authViewModelProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Erreur de connexion'),
          backgroundColor: AppColors.statusAnnulee,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrincipal,
      body: Stack(
        children: [
          // Dégradé de fond décoratif
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coral.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.statusAttente.withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    SvgPicture.asset(
                      'assets/logoText.svg',
                      width: 320,
                      height: 130,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bienvenue sur RoutePulse',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Formulaire dans une card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Connexion',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Nunito',
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Entrez vos identifiants pour continuer',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                fontFamily: 'Nunito',
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                hintText: 'exemple@routepulse.com',
                                enabled: !_isLoading,
                                suffixIcon: _isBiometricAvailable
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.fingerprint,
                                          color: AppColors.coral,
                                          size: 22,
                                        ),
                                        onPressed: _showBiometricDialog,
                                        tooltip: 'Connexion biométrique',
                                      )
                                    : null,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Email requis';
                                if (!v.contains('@') || !v.contains('.')) return 'Email invalide';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              focusNode: _passwordFocusNode,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                enabled: !_isLoading,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Mot de passe requis';
                                if (v.length < 4) return 'Au moins 4 caractères';
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState!.validate()) {
                                          _handleLogin(
                                            _emailCtrl.text.trim(),
                                            _passwordCtrl.text,
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Se connecter',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Lien inscription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Pas de compte ?',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterView()),
                          ),
                          child: const Text(
                            'Créer un compte',
                            style: TextStyle(
                              color: AppColors.coral,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Compte démo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.statusAttente.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.statusAttente.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.lock_open_outlined,
                              color: AppColors.statusAttente,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Compte de démonstration',
                                style: TextStyle(
                                  color: AppColors.statusAttente,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'demo@routepulse.com  •  demo123',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
