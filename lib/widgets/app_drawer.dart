// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'biometric_toggle.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    final authService = AuthService();

    return Drawer(
      backgroundColor: AppColors.bgPrincipal,
      child: SafeArea(
        child: Column(
          children: [
            // Header avec infos utilisateur
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgPrincipal,
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.coral,
                          AppColors.coralLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        user?.initiales ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.nomComplet ?? 'Utilisateur',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  if (user?.phone != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user!.phone!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ✅ OPTION BIOMÉTRIQUE (si utilisateur connecté)
            if (user != null)
              FutureBuilder<bool>(
                future: BiometricService().isBiometricAvailable(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return FutureBuilder<String?>(
                      future: authService.getUserPassword(user.id),
                      builder: (context, passSnapshot) {
                        if (passSnapshot.hasData && passSnapshot.data != null) {
                          return Column(
                            children: [
                              BiometricToggle(
                                userId: user.id,
                                email: user.email,
                                password: passSnapshot.data!,
                                onEnabled: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Connexion biométrique activée'),
                                      backgroundColor: AppColors.statusLivree,
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                onDisabled: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Connexion biométrique désactivée'),
                                      backgroundColor: AppColors.statusCours,
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                              const Divider(color: AppColors.border, height: 32),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

            // Menu items
            _buildMenuItem(
              icon: Icons.person_outline,
              title: 'Mon profil',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité à venir'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: 'Paramètres',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité à venir'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            const Divider(color: AppColors.border, height: 32),

            const Spacer(),

            // Bouton déconnexion
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Déconnexion',
              color: AppColors.statusAnnulee,
              onTap: () async {
                await ref.read(authViewModelProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color color = AppColors.textPrimary,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      onTap: onTap,
    );
  }
}