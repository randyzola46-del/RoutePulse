import 'package:flutter/material.dart';
import '../models/vehicule.dart';  // Contient déjà l'extension EntretienUrgenceX
import '../theme/app_theme.dart';

// ⚠️ L'extension EntretienUrgenceX est déjà définie dans vehicule.dart
// NE PAS la redéfinir ici !

//Bannière d'alerte
class EntretienAlerteBanner extends StatelessWidget {
  final List<EntretienItem> entretiens;

  const EntretienAlerteBanner({super.key, required this.entretiens});

  @override
  Widget build(BuildContext context) {
    // Trouver l'entretien le plus urgent
    final urgents = entretiens.where((e) =>
    e.urgence == EntretienUrgence.rouge || e.urgence == EntretienUrgence.jaune
    ).toList();

    if (urgents.isEmpty) return const SizedBox.shrink();

    // Trier : rouge d'abord, puis jaune
    urgents.sort((a, b) {
      if (a.urgence != b.urgence) {
        return a.urgence == EntretienUrgence.rouge ? -1 : 1;
      }
      return 0;
    });

    final item = urgents.first;
    final color = item.urgence.couleur;  // Utilise l'extension de vehicule.dart

    String delai = '';
    if (item.joursRestants != null) {
      delai = '${item.titre} dans ${item.joursRestants}j';
    } else if (item.kmActuels != null && item.kmEcheance != null) {
      final reste = item.kmEcheance! - item.kmActuels!;
      delai = '${item.titre} dans ${reste} km';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.urgence.icone, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delai,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Prévoyez un rendez-vous atelier',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//Card d'un entretien
class EntretienCard extends StatelessWidget {
  final EntretienItem item;

  const EntretienCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.urgence.couleur;      // Utilise l'extension de vehicule.dart
    final tinte = item.urgence.tinte;        // Utilise l'extension de vehicule.dart
    final icon = item.urgence.icone;         // Utilise l'extension de vehicule.dart

    String etiquetteDelai = '';
    if (item.joursRestants != null) {
      etiquetteDelai = '${item.joursRestants}j';
    } else if (item.kmActuels != null && item.kmEcheance != null) {
      final reste = item.kmEcheance! - item.kmActuels!;
      etiquetteDelai = '+${reste} km';
    }

    String sousTitre = '';
    if (item.typeEcheance == TypeEcheance.km &&
        item.kmActuels != null &&
        item.kmEcheance != null) {
      sousTitre =
      '${_formatKm(item.kmActuels!)} km actuels · échéance ${_formatKm(item.kmEcheance!)} km';
    } else if (item.dateEcheance != null) {
      sousTitre = 'Échéance : ${item.dateEcheance}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icône
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tinte,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              // Titre
              Expanded(
                child: Text(
                  item.titre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              // Badge délai
              Text(
                etiquetteDelai,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Sous-titre
          if (sousTitre.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                sousTitre,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.progressValue.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatKm(int km) {
    if (km >= 1000) {
      final s = km.toString();
      final parts = <String>[];
      var i = s.length;
      while (i > 0) {
        final start = (i - 3).clamp(0, i);
        parts.insert(0, s.substring(start, i));
        i = start;
      }
      return parts.join(' ');
    }
    return km.toString();
  }
}