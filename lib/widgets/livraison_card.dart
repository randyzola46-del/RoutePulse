import 'package:flutter/material.dart';
import 'dart:math';
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

  Color _getColorFromString(String text) {
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = (hash + text.codeUnitAt(i)) % 360;
    }
    return HSLColor.fromAHSL(1.0, hash.toDouble(), 0.7, 0.6).toColor();
  }

  double _getLuminance(Color color) {
    double linearize(double component) {
      if (component <= 0.03928) return component / 12.92;
      return pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
    double r = linearize(color.red / 255);
    double g = linearize(color.green / 255);
    double b = linearize(color.blue / 255);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    final luminance = _getLuminance(backgroundColor);
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final color = statutColor(livraison.statut);
    final initialesColor = _getColorFromString(livraison.nomClient);
    final textColorForInitiales = _getTextColorForBackground(initialesColor);

    // Plus de suppression automatique - les livraisons livrées restent dans la liste

    return Dismissible(
      key: Key(livraison.id),
      direction: DismissDirection.endToStart,
      background: _deleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: livraison.statut.isFinal ? null : onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: livraison.statut.isFinal
                ? AppColors.surface2.withOpacity(0.5)
                : AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: livraison.statut.isFinal
                ? Border.all(color: color.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: initialesColor.withOpacity(livraison.statut.isFinal ? 0.5 : 1.0),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initiales(livraison.nomClient),
                  style: TextStyle(
                    color: textColorForInitiales,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      livraison.nomClient,
                      style: TextStyle(
                        color: livraison.statut.isFinal
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                        decoration: livraison.statut == StatutLivraison.annulee
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      livraison.adresse,
                      style: TextStyle(
                        color: livraison.statut.isFinal
                            ? AppColors.textMuted.withOpacity(0.7)
                            : AppColors.coral,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Nunito',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12,
                            color: livraison.statut.isFinal
                                ? AppColors.textMuted.withOpacity(0.7)
                                : AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(livraison.creneau,
                            style: TextStyle(
                                color: livraison.statut.isFinal
                                    ? AppColors.textMuted.withOpacity(0.7)
                                    : AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                        Icon(Icons.scale, size: 12,
                            color: livraison.statut.isFinal
                                ? AppColors.textMuted.withOpacity(0.7)
                                : AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('${livraison.poids.toStringAsFixed(1)} kg',
                            style: TextStyle(
                                color: livraison.statut.isFinal
                                    ? AppColors.textMuted.withOpacity(0.7)
                                    : AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatutBadge(
                statut: livraison.statut,
                color: color,
                onChanged: onStatutChange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.statusAnnulee.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.statusAnnulee.withOpacity(0.3), width: 0.5),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline, color: AppColors.statusAnnulee, size: 24),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ?',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text('Supprimer la livraison de ${livraison.nomClient} ?',
            style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusAnnulee),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _initiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nom.substring(0, 2).toUpperCase();
  }
}

// Badge avec menu intelligent
class _StatutBadge extends StatelessWidget {
  final StatutLivraison statut;
  final Color color;
  final void Function(StatutLivraison) onChanged;

  const _StatutBadge({
    required this.statut,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // États finaux : badge non cliquable
    if (statut.isFinal) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          statut.label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
          ),
        ),
      );
    }

    // États actifs : badge cliquable
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statut.label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    final actions = statut.availableActions;
    if (actions.isEmpty) {
      _showReadOnlyMessage(context);
      return;
    }
    _showActionMenu(context, actions);
  }

  void _showActionMenu(BuildContext context, List<StatutLivraison> actions) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + button.size.height,
        offset.dx + button.size.width,
        offset.dy + button.size.height,
      ),
      items: actions.map((status) {
        final statusColor = statutColor(status);
        return PopupMenuItem(
          value: status,
          child: Row(
            children: [
              Icon(status.actionIcon, size: 20, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.actionLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      _getActionSubtitle(status),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((newStatus) {
      if (newStatus != null && newStatus != statut) {
        _applyStatusChange(context, newStatus);
      }
    });
  }

  String _getActionSubtitle(StatutLivraison status) {
    switch (status) {
      case StatutLivraison.enCours:
        return "Passer le statut à 'En cours'";
      case StatutLivraison.livree:
        return "La livraison sera marquée comme terminée";
      case StatutLivraison.annulee:
        return "La livraison sera annulée";
      case StatutLivraison.aReporter:
        return "Remettre en attente pour plus tard";
      case StatutLivraison.enAttente:
        return "La livraison pourra être reprise plus tard";
    }
  }

  void _applyStatusChange(BuildContext context, StatutLivraison newStatus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getSuccessMessage(newStatus)),
        backgroundColor: statutColor(newStatus),
        duration: const Duration(seconds: 2),
      ),
    );
    onChanged(newStatus);
  }

  String _getSuccessMessage(StatutLivraison status) {
    switch (status) {
      case StatutLivraison.enCours:
        return "Livraison démarrée !";
      case StatutLivraison.livree:
        return "Livraison terminée avec succès !";
      case StatutLivraison.annulee:
        return "Livraison annulée";
      case StatutLivraison.aReporter:
        return "Livraison reportée à plus tard";
      case StatutLivraison.enAttente:
        return "Livraison remise en attente";
    }
  }

  void _showReadOnlyMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          statut == StatutLivraison.livree
              ? "✓ Livraison terminée - Aucune action possible"
              : "✗ Livraison annulée - Aucune action possible",
        ),
        backgroundColor: statut == StatutLivraison.livree ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}