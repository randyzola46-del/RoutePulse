// lib/widgets/dashboard_header.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

//Header du Dashboard : greeting, date, barre de progression.
class DashboardHeader extends StatelessWidget {
  final double progress;
  final int total;
  final int livrees;
  final String userName;  // ✅ NOUVEAU : nom de l'utilisateur

  const DashboardHeader({
    super.key,
    required this.progress,
    required this.total,
    required this.livrees,
    required this.userName,  // ✅ NOUVEAU
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.bgPrincipal,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Bonjour${userName.isNotEmpty ? ',' : ''}',
            style: tt.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
          Text(
            userName.isNotEmpty ? userName : 'Invité',
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 20),

          // Date + badge pourcentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(DateTime.now()),
                style: tt.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              _CompletionBadge(pct: (progress * 100).round()),
            ],
          ),
          const SizedBox(height: 12),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation(AppColors.coral),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$livrees livrées sur $total',
            style: tt.bodySmall?.copyWith(
              color: AppColors.coral,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  //Formate une date en « Lundi 7 avril 2025 » (français).
  static String _formatDate(DateTime d) {
    const jours = [
      'Dimanche', 'Lundi', 'Mardi', 'Mercredi',
      'Jeudi', 'Vendredi', 'Samedi',
    ];
    const mois = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${jours[d.weekday % 7]} ${d.day} ${mois[d.month]} ${d.year}';
  }
}


// Badge affichant le pourcentage de complétion des livraisons du jour.
class _CompletionBadge extends StatelessWidget {
  final int pct;
  const _CompletionBadge({required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.coral.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$pct% complété',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.coral,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}