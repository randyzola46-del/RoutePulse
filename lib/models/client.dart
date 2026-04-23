import 'dart:convert';

enum RangClient { gold, silver, bronze, standard }

extension RangClientX on RangClient {
  String get label {
    switch (this) {
      case RangClient.gold:
        return 'Gold';
      case RangClient.silver:
        return 'Silver';
      case RangClient.bronze:
        return 'Bronze';
      case RangClient.standard:
        return 'Standard';
    }
  }

  String get toJson {
    switch (this) {
      case RangClient.gold:
        return 'gold';
      case RangClient.silver:
        return 'silver';
      case RangClient.bronze:
        return 'bronze';
      case RangClient.standard:
        return 'standard';
    }
  }
}

RangClient rangClientFromJson(String value) {
  switch (value) {
    case 'gold':
      return RangClient.gold;
    case 'silver':
      return RangClient.silver;
    case 'bronze':
      return RangClient.bronze;
    default:
      return RangClient.standard;
  }
}

class Client {
  final String id;
  final String prenom;
  final String nom;
  final String adresse;
  final String? phone;
  final RangClient rang;
  final bool estRecurrent;
  final int livraisonsTotal;
  final double tauxSucces;
  final String creneauPrefere;
  final DateTime dateCreation;
  final String? notes;

  const Client({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.adresse,
    this.phone,
    required this.rang,
    required this.estRecurrent,
    required this.livraisonsTotal,
    required this.tauxSucces,
    required this.creneauPrefere,
    required this.dateCreation,
    this.notes,
  });

  String get nomComplet => '$prenom $nom';

  String get initiales {
    final prenomInitial = prenom.isNotEmpty ? prenom[0] : '';
    final nomInitial = nom.isNotEmpty ? nom[0] : '';

    if (prenomInitial.isEmpty && nomInitial.isEmpty) {
      return '??';
    }

    if (prenomInitial.isEmpty) {
      return nomInitial.toUpperCase();
    }

    if (nomInitial.isEmpty) {
      return prenomInitial.toUpperCase();
    }

    return '${prenomInitial}${nomInitial}'.toUpperCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prenom': prenom,
      'nom': nom,
      'adresse': adresse,
      'phone': phone,
      'rang': rang.toJson,
      'est_recurrent': estRecurrent ? 1 : 0,
      'livraisons_total': livraisonsTotal,
      'taux_succes': tauxSucces,
      'creneau_prefere': creneauPrefere,
      'date_creation': dateCreation.toIso8601String(),
      'notes': notes,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      prenom: map['prenom'] ?? '',
      nom: map['nom'] ?? '',
      adresse: map['adresse'] ?? '',
      phone: map['phone'],
      rang: rangClientFromJson(map['rang'] ?? 'standard'),
      estRecurrent: map['est_recurrent'] == 1,
      livraisonsTotal: map['livraisons_total'] ?? 0,
      tauxSucces: (map['taux_succes'] ?? 0.0).toDouble(),
      creneauPrefere: map['creneau_prefere'] ?? '09:00 - 12:00',
      dateCreation: DateTime.parse(map['date_creation'] ?? DateTime.now().toIso8601String()),
      notes: map['notes'],
    );
  }

  Client copyWith({
    String? id,
    String? prenom,
    String? nom,
    String? adresse,
    String? phone,
    RangClient? rang,
    bool? estRecurrent,
    int? livraisonsTotal,
    double? tauxSucces,
    String? creneauPrefere,
    DateTime? dateCreation,
    String? notes,
  }) {
    return Client(
      id: id ?? this.id,
      prenom: prenom ?? this.prenom,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      phone: phone ?? this.phone,
      rang: rang ?? this.rang,
      estRecurrent: estRecurrent ?? this.estRecurrent,
      livraisonsTotal: livraisonsTotal ?? this.livraisonsTotal,
      tauxSucces: tauxSucces ?? this.tauxSucces,
      creneauPrefere: creneauPrefere ?? this.creneauPrefere,
      dateCreation: dateCreation ?? this.dateCreation,
      notes: notes ?? this.notes,
    );
  }
}

enum StatutHistorique { livree, reportee, echouee }

extension StatutHistoriqueX on StatutHistorique {
  String get label {
    switch (this) {
      case StatutHistorique.livree:
        return 'Livrée';
      case StatutHistorique.reportee:
        return 'Reportée';
      case StatutHistorique.echouee:
        return 'Échouée';
    }
  }
}

class HistoriqueLivraison {
  final String id;
  final String clientId;
  final String date;
  final String adresse;
  final StatutHistorique statut;
  final String? livraisonId;

  const HistoriqueLivraison({
    required this.id,
    required this.clientId,
    required this.date,
    required this.adresse,
    required this.statut,
    this.livraisonId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'date': date,
      'adresse': adresse,
      'statut': statut.label,
      'livraison_id': livraisonId,
    };
  }

  factory HistoriqueLivraison.fromMap(Map<String, dynamic> map) {
    StatutHistorique statut;
    switch (map['statut']) {
      case 'Livrée':
        statut = StatutHistorique.livree;
        break;
      case 'Reportée':
        statut = StatutHistorique.reportee;
        break;
      default:
        statut = StatutHistorique.echouee;
    }
    return HistoriqueLivraison(
      id: map['id'] ?? '',
      clientId: map['client_id'] ?? '',
      date: map['date'] ?? '',
      adresse: map['adresse'] ?? '',
      statut: statut,
      livraisonId: map['livraison_id'],
    );
  }
}