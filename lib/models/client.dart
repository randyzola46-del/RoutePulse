enum RangClient { gold, silver, bronze, standard }

extension RangClientX on RangClient {
  String get label {
    switch (this) {
      case RangClient.gold:     return 'Gold';
      case RangClient.silver:   return 'Silver';
      case RangClient.bronze:   return 'Bronze';
      case RangClient.standard: return 'Standard';
    }
  }
}

class Client {
  final String id;
  final String prenom;
  final String nom;
  final String adresse;
  final RangClient rang;
  final bool estRecurrent;
  final int livraisonsTotal;
  final double tauxSucces;
  final String creneauPrefere;
  final List<HistoriqueLivraison> historique;

  const Client({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.adresse,
    required this.rang,
    required this.estRecurrent,
    required this.livraisonsTotal,
    required this.tauxSucces,
    required this.creneauPrefere,
    required this.historique,
  });

  String get nomComplet => '$prenom $nom';
  String get initiales => '${prenom[0]}${nom[0]}';

  Client copyWith({
    String? id,
    String? prenom,
    String? nom,
    String? adresse,
    RangClient? rang,
    bool? estRecurrent,
    int? livraisonsTotal,
    double? tauxSucces,
    String? creneauPrefere,
    List<HistoriqueLivraison>? historique,
  }) {
    return Client(
      id: id ?? this.id,
      prenom: prenom ?? this.prenom,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      rang: rang ?? this.rang,
      estRecurrent: estRecurrent ?? this.estRecurrent,
      livraisonsTotal: livraisonsTotal ?? this.livraisonsTotal,
      tauxSucces: tauxSucces ?? this.tauxSucces,
      creneauPrefere: creneauPrefere ?? this.creneauPrefere,
      historique: historique ?? this.historique,
    );
  }
}

enum StatutHistorique { livree, reportee, echouee }

extension StatutHistoriqueX on StatutHistorique {
  String get label {
    switch (this) {
      case StatutHistorique.livree:   return 'Livrée';
      case StatutHistorique.reportee: return 'Reportée';
      case StatutHistorique.echouee:  return 'Échouée';
    }
  }
}

class HistoriqueLivraison {
  final String date;
  final String adresse;
  final StatutHistorique statut;

  const HistoriqueLivraison({
    required this.date,
    required this.adresse,
    required this.statut,
  });
}
