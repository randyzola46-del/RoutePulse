enum StatutLivraison {
  enAttente,
  enCours,
  livree,
  aReporter,
  annulee,
}

extension StatutLivraisonX on StatutLivraison {
  String get label {
    switch (this) {
      case StatutLivraison.enAttente:
        return 'En attente';
      case StatutLivraison.enCours:
        return 'En cours';
      case StatutLivraison.livree:
        return 'Livrée';
      case StatutLivraison.aReporter:
        return 'À reporter';
      case StatutLivraison.annulee:
        return 'Annulée';
    }
  }
}

class Livraison {
  final String id;
  final String nomClient;
  final String adresse;
  final String creneau;
  final int nbColis;
  final double poids;
  final StatutLivraison statut;
  final String? notes;
  final DateTime dateCreation;

  const Livraison({
    required this.id,
    required this.nomClient,
    required this.adresse,
    required this.creneau,
    required this.nbColis,
    required this.poids,
    required this.statut,
    this.notes,
    required this.dateCreation,
  });

  Livraison copyWith({
    String? id,
    String? nomClient,
    String? adresse,
    String? creneau,
    int? nbColis,
    double? poids,
    StatutLivraison? statut,
    String? notes,
    DateTime? dateCreation,
  }) {
    return Livraison(
      id: id ?? this.id,
      nomClient: nomClient ?? this.nomClient,
      adresse: adresse ?? this.adresse,
      creneau: creneau ?? this.creneau,
      nbColis: nbColis ?? this.nbColis,
      poids: poids ?? this.poids,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}
