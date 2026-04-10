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

  String get toJson {
    switch (this) {
      case StatutLivraison.enAttente:
        return 'en_attente';
      case StatutLivraison.enCours:
        return 'en_cours';
      case StatutLivraison.livree:
        return 'livree';
      case StatutLivraison.aReporter:
        return 'a_reporter';
      case StatutLivraison.annulee:
        return 'annulee';
    }
  }

  bool get isFinal {
    return this == StatutLivraison.livree || this == StatutLivraison.annulee;
  }

  List<StatutLivraison> get availableActions {
    switch (this) {
      case StatutLivraison.enAttente:
        return [StatutLivraison.enCours];
      case StatutLivraison.enCours:
        return [StatutLivraison.livree, StatutLivraison.annulee, StatutLivraison.aReporter];
      case StatutLivraison.aReporter:
        return [StatutLivraison.enAttente, StatutLivraison.annulee];
      case StatutLivraison.livree:
      case StatutLivraison.annulee:
        return [];
    }
  }
}

// ✅ Fonction statique pour convertir du JSON
StatutLivraison statutLivraisonFromJson(String value) {
  switch (value) {
    case 'en_cours':
      return StatutLivraison.enCours;
    case 'livree':
      return StatutLivraison.livree;
    case 'a_reporter':
      return StatutLivraison.aReporter;
    case 'annulee':
      return StatutLivraison.annulee;
    default:
      return StatutLivraison.enAttente;
  }
}

class Livraison {
  final String id;
  final String clientId;
  final String nomClient;
  final String adresse;
  final String creneau;
  final int nbColis;
  final double poids;
  final StatutLivraison statut;
  final String? notes;
  final DateTime dateCreation;
  final String? vehiculeId;
  final String? historiqueId;

  const Livraison({
    required this.id,
    required this.clientId,
    required this.nomClient,
    required this.adresse,
    required this.creneau,
    required this.nbColis,
    required this.poids,
    required this.statut,
    this.notes,
    required this.dateCreation,
    this.vehiculeId,
    this.historiqueId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'nom_client': nomClient,
      'adresse': adresse,
      'creneau': creneau,
      'nb_colis': nbColis,
      'poids': poids,
      'statut': statut.toJson,
      'notes': notes,
      'date_creation': dateCreation.toIso8601String(),
      'vehicule_id': vehiculeId,
      'historique_id': historiqueId,
    };
  }

  factory Livraison.fromMap(Map<String, dynamic> map) {
    return Livraison(
      id: map['id'],
      clientId: map['client_id'],
      nomClient: map['nom_client'],
      adresse: map['adresse'],
      creneau: map['creneau'],
      nbColis: map['nb_colis'],
      poids: map['poids'],
      statut: statutLivraisonFromJson(map['statut']), // ✅ Utiliser la fonction statique
      notes: map['notes'],
      dateCreation: DateTime.parse(map['date_creation']),
      vehiculeId: map['vehicule_id'],
      historiqueId: map['historique_id'],
    );
  }

  Livraison copyWith({
    String? id,
    String? clientId,
    String? nomClient,
    String? adresse,
    String? creneau,
    int? nbColis,
    double? poids,
    StatutLivraison? statut,
    String? notes,
    DateTime? dateCreation,
    String? vehiculeId,
    String? historiqueId,
  }) {
    return Livraison(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      nomClient: nomClient ?? this.nomClient,
      adresse: adresse ?? this.adresse,
      creneau: creneau ?? this.creneau,
      nbColis: nbColis ?? this.nbColis,
      poids: poids ?? this.poids,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      dateCreation: dateCreation ?? this.dateCreation,
      vehiculeId: vehiculeId ?? this.vehiculeId,
      historiqueId: historiqueId ?? this.historiqueId,
    );
  }
}