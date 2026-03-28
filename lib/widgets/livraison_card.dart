import 'package:flutter/material.dart';
import '../models/livraison.dart';
import '../theme/app_theme.dart';

class LivraisonCard extends StatelessWidget {
  final Livraison livraison;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(StatutLivraison) onStatutChange;

  const LivraisonCard({
    super.key,
    required this.livraison,
    required this.onTap,
    required this.onDelete,
    required this.onStatutChange,
  });

  @override
  Widget build(BuildContext context) {
    final color = statutColor(livraison.statut);

    return Dismissible(
      key: Key(livraison.id),
      direction: DismissDirection.endToStart,
      background: _deleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(color),
                const SizedBox(height: 6),
                _buildAddress(),
                const SizedBox(height: 10),
                _buildFooter(color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Row(
      children: [
        // Avatar initiales
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.coral.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            _initiales(livraison.nomClient),
            style: const TextStyle(
              color: AppColors.coral,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                livraison.nomClient,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                livraison.creneau,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _StatutBadge(statut: livraison.statut, color: color),
      ],
    );
  }

  Widget _buildAddress() {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined,
            size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            livraison.adresse,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(Color color) {
    return Row(
      children: [
        _MetaChip(icon: Icons.inventory_2_outlined,
            label: '${livraison.nbColis} colis'),
        const SizedBox(width: 8),
        _MetaChip(icon: Icons.scale_outlined,
            label: '${livraison.poids} kg'),
        const Spacer(),
        // Barre de progression statut
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _progressValue(livraison.statut),
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deleteBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.statusAnnulee.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.statusAnnulee.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline,
          color: AppColors.statusAnnulee, size: 24),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ?',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          'Supprimer la livraison de ${livraison.nomClient} ?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusAnnulee,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _initiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nom.substring(0, 2).toUpperCase();
  }

  double _progressValue(StatutLivraison s) {
    switch (s) {
      case StatutLivraison.enAttente:
        return 0.0;
      case StatutLivraison.enCours:
        return 0.5;
      case StatutLivraison.livree:
        return 1.0;
      case StatutLivraison.aReporter:
        return 0.3;
      case StatutLivraison.annulee:
        return 0.0;
    }
  }
}

//Sous-widgets

class _StatutBadge extends StatelessWidget {
  final StatutLivraison statut;
  final Color color;

  const _StatutBadge({required this.statut, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            statut.label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
