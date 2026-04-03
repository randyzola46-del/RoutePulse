import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Grille 2×2 des indicateurs clés (KPI) du tableau de bord.
class DashboardKpiGrid extends StatelessWidget {
  final int total;
  final int livrees;
  final int enCours;
  final int retard;

  const DashboardKpiGrid({
    super.key,
    required this.total,
    required this.livrees,
    required this.enCours,
    required this.retard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          _KpiCard(
            value: total,
            label: 'Total',
            color: AppColors.coral,
            tint: AppColors.coral.withOpacity(0.10),
          ),
          const SizedBox(width: 12),
          _KpiCard(
            value: livrees,
            label: 'Livrées',
            color: AppColors.statusLivree,
            tint: AppColors.statusLivree.withOpacity(0.10),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _KpiCard(
            value: enCours,
            label: 'En cours',
            color: AppColors.statusCours,
            tint: AppColors.statusCours.withOpacity(0.10),
          ),
          const SizedBox(width: 12),
          _KpiCard(
            value: retard,
            label: 'Retard',
            color: AppColors.statusReporter,
            tint: AppColors.statusReporter.withOpacity(0.10),
          ),
        ]),
      ],
    );
  }
}

//Widget privé

/// Carte KPI individuelle : grande valeur + libellé.
class _KpiCard extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final Color tint;

  const _KpiCard({
    required this.value,
    required this.label,
    required this.color,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withOpacity(0.7),
            width: 2.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: tt.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 31,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
