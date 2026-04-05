import 'package:flutter/material.dart';
import '../models/vehicule.dart';
import '../theme/app_theme.dart';

//Couleurs par urgence
extension EntretienUrgenceX on EntretienUrgence {
  Color get couleur {
    switch (this) {
      case EntretienUrgence.rouge: return const Color(0xFFEA4E4E);
      case EntretienUrgence.jaune: return const Color(0xFFFFB572);
      case EntretienUrgence.vert:  return const Color(0xFF50D1AA);
    }
  }

  Color get tinte {
    switch (this) {
      case EntretienUrgence.rouge: return const Color(0x22EA4E4E);
      case EntretienUrgence.jaune: return const Color(0x22FFB572);
      case EntretienUrgence.vert:  return const Color(0x2250D1AA);
    }
  }

  IconData get icone {
    switch (this) {
      case EntretienUrgence.rouge: return Icons.warning_rounded;
      case EntretienUrgence.jaune: return Icons.info_rounded;
      case EntretienUrgence.vert:  return Icons.shield_rounded;
    }
  }
}

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

    // Trier : rouge d'abord, puis jaune, puis par jours/km restants
    urgents.sort((a, b) {
      if (a.urgence != b.urgence) {
        return a.urgence == EntretienUrgence.rouge ? -1 : 1;
      }
      return 0;
    });

    final item = urgents.first;
    final color = item.urgence.couleur;
    final isRouge = item.urgence == EntretienUrgence.rouge;

    String sousTitre;
    if (item.typeEcheance == TypeEcheance.km && item.joursRestants != null) {
      sousTitre = 'Prévoyez un rendez-vous atelier';
    } else if (item.joursRestants != null) {
      sousTitre = 'Prévoyez un rendez-vous atelier';
    } else {
      sousTitre = 'Prévoyez un rendez-vous atelier';
    }

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
            child: Icon(Icons.warning_rounded, color: color, size: 20),
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
                Text(
                  sousTitre,
                  style: const TextStyle(
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
    final color = item.urgence.couleur;
    final tinte = item.urgence.tinte;
    final icon  = item.urgence.icone;

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
                    fontSize: 20,
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
                  fontSize: 13,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.progressValue,
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
