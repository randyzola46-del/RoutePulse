// lib/widgets/biometric_toggle.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';

class BiometricToggle extends ConsumerStatefulWidget {
  final String userId;
  final String email;
  final String password;
  final VoidCallback onEnabled;
  final VoidCallback onDisabled;

  const BiometricToggle({
    super.key,
    required this.userId,
    required this.email,
    required this.password,
    required this.onEnabled,
    required this.onDisabled,
  });

  @override
  ConsumerState<BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends ConsumerState<BiometricToggle> {
  final BiometricService _biometricService = BiometricService();
  bool _isEnabled = false;
  bool _isAvailable = false;
  bool _isLoading = true;
  List<BiometricTypeEnum> _availableTypes = [];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);

    _isAvailable = await _biometricService.isBiometricAvailable();
    _availableTypes = await _biometricService.getAvailableBiometrics();
    _isEnabled = await _biometricService.getBiometricPreference(widget.userId);

    setState(() => _isLoading = false);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_isAvailable) {
      _showNotAvailableDialog();
      return;
    }

    if (value) {
      // Activer : tester d'abord l'authentification
      final result = await _biometricService.authenticate(
        reason: 'Activez la connexion biométrique pour ${widget.email}',
        title: 'Activer la biométrie',
        subtitle: 'Vérifiez votre identité',
      );

      if (result.isSuccess && mounted) {
        await _biometricService.saveBiometricPreference(widget.userId, true);
        await _biometricService.saveBiometricCredentials(widget.userId, widget.email, widget.password);
        setState(() => _isEnabled = true);
        widget.onEnabled();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connexion biométrique activée'),
            backgroundColor: AppColors.statusLivree,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.statusAnnulee,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Désactiver
      await _biometricService.saveBiometricPreference(widget.userId, false);
      await _biometricService.clearBiometricCredentials(widget.userId);
      setState(() => _isEnabled = false);
      widget.onDisabled();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connexion biométrique désactivée'),
          backgroundColor: AppColors.statusCours,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.fingerprint, color: AppColors.statusCours),
            SizedBox(width: 12),
            Text('Biométrie non disponible'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre appareil ne supporte pas la biométrie ou aucune empreinte/visage n\'est enregistré.',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            if (_availableTypes.isEmpty)
              const Text(
                '💡 Pour utiliser cette fonction, activez la biométrie dans les paramètres de votre téléphone.',
                style: TextStyle(fontSize: 12, color: AppColors.statusAttente),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getBiometricLabel(BiometricTypeEnum type) {
    switch (type) {
      case BiometricTypeEnum.fingerprint:
        return 'empreinte digitale';
      case BiometricTypeEnum.face:
        return 'reconnaissance faciale';
      case BiometricTypeEnum.iris:
        return 'reconnaissance irienne';
      case BiometricTypeEnum.strong:
        return 'biométrie forte';
      case BiometricTypeEnum.weak:
        return 'biométrie faible';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final biometricIcon = _availableTypes.isNotEmpty
        ? _getBiometricIcon(_availableTypes.first)
        : Icons.fingerprint;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        dense: true,
        activeColor: AppColors.coral,
        title: Row(
          children: [
            Icon(biometricIcon, size: 20, color: AppColors.coral),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Connexion biométrique',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        subtitle: _availableTypes.isNotEmpty
            ? Text(
          'Utiliser ${_availableTypes.map((t) => _getBiometricLabel(t)).join(' ou ')}',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        )
            : const Text(
          'Non disponible',
          style: TextStyle(fontSize: 11, color: AppColors.statusReporter),
        ),
        value: _isEnabled && _isAvailable,
        onChanged: _isAvailable ? _toggleBiometric : null,
      ),
    );
  }
}