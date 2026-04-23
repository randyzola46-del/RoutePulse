import 'package:flutter/material.dart';
import '../models/livraison.dart';
import '../theme/app_theme.dart';

class SnackBarUtils {
  // Afficher un SnackBar de succès (vert)
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.statusLivree,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.statusLivree.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  // Afficher un SnackBar d'erreur (rouge)
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.statusAnnulee,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.statusAnnulee.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  // Afficher un SnackBar d'information (bleu/orange selon contexte)
  static void showInfo(BuildContext context, String message, Color textColor) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  // Afficher un SnackBar pour changement de statut
  static void showStatutChange(BuildContext context, StatutLivraison newStatut, String message) {
    final Color textColor = statutColor(newStatut);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconForStatut(newStatut),
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  static IconData _getIconForStatut(StatutLivraison statut) {
    switch (statut) {
      case StatutLivraison.enCours:
        return Icons.play_arrow;
      case StatutLivraison.livree:
        return Icons.check_circle;
      case StatutLivraison.annulee:
        return Icons.cancel;
      case StatutLivraison.aReporter:
        return Icons.schedule;
      case StatutLivraison.enAttente:
        return Icons.pending;
    }
  }
}