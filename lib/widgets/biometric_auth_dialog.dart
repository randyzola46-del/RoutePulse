// lib/widgets/biometric_auth_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';

class BiometricAuthDialog extends ConsumerStatefulWidget {
  final String email;
  final VoidCallback onSuccess;
  final VoidCallback onUsePassword;
  final VoidCallback? onCancel;

  const BiometricAuthDialog({
    super.key,
    required this.email,
    required this.onSuccess,
    required this.onUsePassword,
    this.onCancel,
  });

  @override
  ConsumerState<BiometricAuthDialog> createState() => _BiometricAuthDialogState();
}

class _BiometricAuthDialogState extends ConsumerState<BiometricAuthDialog> {
  final BiometricService _biometricService = BiometricService();
  bool _isAuthenticating = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAuthentication();
      }
    });
  }

  Future<void> _startAuthentication() async {
    if (_isAuthenticating || _isSuccess || !mounted) return;

    setState(() => _isAuthenticating = true);

    try {
      final result = await _biometricService.authenticateSimple(
        reason: 'Connectez-vous à RoutePulse',
      );

      if (!mounted) return;

      setState(() => _isAuthenticating = false);

      if (result == BiometricResult.success) {
        _isSuccess = true;

        // ✅ 1. Fermer d'abord le dialogue
        if (mounted) {
          Navigator.of(context).pop();
        }

        // ✅ 2. Puis appeler le callback de succès
        // Petit délai pour que le dialogue soit bien fermé
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            widget.onSuccess();
          }
        });
      } else if (result == BiometricResult.cancelled) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onUsePassword();
        }
      } else if (result != BiometricResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.statusAnnulee,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        _isAuthenticating = false;
      }
    } catch (e) {
      print('Erreur authentification: $e');
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.coral,
                    AppColors.coralLight,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fingerprint,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Connexion biométrique',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              widget.email,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            if (_isAuthenticating) ...[
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vérification en cours...',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onUsePassword();
                },
                child: const Text('Annuler'),
              ),
            ] else ...[
              const Text(
                'Utilisez votre empreinte digitale pour vous connecter',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onUsePassword();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textMuted),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Mot de passe'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startAuthentication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fingerprint, size: 18),
                          SizedBox(width: 8),
                          Text('Réessayer'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}