import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

//État vide du dashboard quand aucune livraison n'est planifiée aujourd'hui.
class DashboardEmptyState extends StatelessWidget {
  final VoidCallback onAjouter;

  const DashboardEmptyState({super.key, required this.onAjouter});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.coral.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: AppColors.coral,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Aucune livraison aujourd'hui",
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajoutez votre première livraison',
            style: tt.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
