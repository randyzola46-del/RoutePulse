// lib/views/register_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/biometric_service.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _biometricEnabled = false;
  bool _isBiometricAvailable = false;
  List<BiometricTypeEnum> _availableBiometrics = [];

  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final types = await _biometricService.getAvailableBiometrics();
    setState(() {
      _isBiometricAvailable = isAvailable;
      _availableBiometrics = types;
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: AppColors.statusAnnulee,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(authViewModelProvider.notifier).register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // ✅ Attendre que l'utilisateur soit bien dans le state
      await Future.delayed(const Duration(milliseconds: 200));

      final user = ref.read(authViewModelProvider).user;
      print('👤 [Register] Utilisateur créé: ${user?.id}');
      print('🔐 [Register] Biométrie activée: $_biometricEnabled');
      print('📱 [Register] Biométrie disponible: $_isBiometricAvailable');

      // ✅ Sauvegarde des identifiants biométriques si activée
      if (_biometricEnabled && _isBiometricAvailable && user != null) {
        print('💾 [Register] Sauvegarde des credentials biométriques...');
        await _biometricService.saveBiometricPreference(user.id, true);
        await _biometricService.saveBiometricCredentials(
          user.id,
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );

        // ✅ Sauvegarde aussi l'email pour la connexion rapide
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_biometric_email', _emailCtrl.text.trim());

        print('✅ [Register] Credentials biométriques sauvegardés avec succès');

        // Vérification immédiate
        final checkPref = await _biometricService.getBiometricPreference(user.id);
        final checkCreds = await _biometricService.getBiometricCredentials(user.id);
        print('🔍 [Register] Vérification - Préférence: $checkPref, Credentials: ${checkCreds != null}');
      } else if (_biometricEnabled && user != null) {
        print('⚠️ [Register] Biométrie activée mais non disponible ou utilisateur null');
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé avec succès !'),
          backgroundColor: AppColors.statusLivree,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      final error = ref.read(authViewModelProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Erreur d\'inscription'),
          backgroundColor: AppColors.statusAnnulee,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _enableBiometric() async {
    if (!_isBiometricAvailable) return;

    final result = await _biometricService.authenticate(
      reason: 'Activez la connexion biométrique pour ${_emailCtrl.text.trim()}',
      title: 'Activer la biométrie',
      subtitle: 'Vérifiez votre identité',
    );

    if (result.isSuccess && mounted) {
      setState(() => _biometricEnabled = true);
      print('✅ [Register] Biométrie activée par l\'utilisateur');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connexion biométrique activée'),
          backgroundColor: AppColors.statusLivree,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted && result != BiometricResult.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
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
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations personnelles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prenomCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nomCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email requis';
                    if (!v.contains('@') || !v.contains('.')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (optionnel)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Sécurité',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 4) return 'Au moins 4 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_isBiometricAvailable) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.coral.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _availableBiometrics.isNotEmpty
                                ? _getBiometricIcon(_availableBiometrics.first)
                                : Icons.fingerprint,
                            size: 20,
                            color: AppColors.coral,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Connexion rapide',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _availableBiometrics.isNotEmpty
                                    ? 'Connectez-vous avec ${_getBiometricLabel(_availableBiometrics.first)}'
                                    : 'Activez la connexion biométrique',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _biometricEnabled,
                          onChanged: (value) async {
                            if (value) {
                              await _enableBiometric();
                            } else {
                              setState(() => _biometricEnabled = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Connexion biométrique désactivée'),
                                  backgroundColor: AppColors.statusCours,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          activeColor: AppColors.coral,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                    'Créer mon compte',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Déjà un compte ?',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(color: AppColors.coral),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getBiometricLabel(BiometricTypeEnum type) {
    switch (type) {
      case BiometricTypeEnum.fingerprint:
        return 'l\'empreinte digitale';
      case BiometricTypeEnum.face:
        return 'la reconnaissance faciale';
      case BiometricTypeEnum.iris:
        return 'la reconnaissance irienne';
      case BiometricTypeEnum.strong:
        return 'la biométrie forte';
      case BiometricTypeEnum.weak:
        return 'la biométrie faible';
    }
  }

  IconData _getBiometricIcon(BiometricTypeEnum type) {
    switch (type) {
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