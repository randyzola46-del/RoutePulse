import 'dart:ui';

import 'package:flutter/material.dart';

enum DisponibiliteVehicule { disponible, indisponible }

extension DisponibiliteVehiculeX on DisponibiliteVehicule {
  String get label {
    switch (this) {
      case DisponibiliteVehicule.disponible:
        return 'Disponible';
      case DisponibiliteVehicule.indisponible:
        return 'Indisponible';
    }
  }

  String get toJson {
    switch (this) {
      case DisponibiliteVehicule.disponible:
        return 'disponible';
      case DisponibiliteVehicule.indisponible:
        return 'indisponible';
    }
  }
}

//Fonction statique pour convertir du JSON
DisponibiliteVehicule disponibiliteVehiculeFromJson(String value) {
  return value == 'disponible'
      ? DisponibiliteVehicule.disponible
      : DisponibiliteVehicule.indisponible;
}

enum TypeEcheance { km, date }

enum EntretienUrgence { rouge, jaune, vert }

extension EntretienUrgenceX on EntretienUrgence {
  Color get couleur {
    switch (this) {
      case EntretienUrgence.rouge:
        return const Color(0xFFEA4E4E);
      case EntretienUrgence.jaune:
        return const Color(0xFFFFB572);
      case EntretienUrgence.vert:
        return const Color(0xFF50D1AA);
    }
  }

  //Ajout du getter tinte (fond avec opacité)
  Color get tinte {
    switch (this) {
      case EntretienUrgence.rouge:
        return const Color(0x22EA4E4E);
      case EntretienUrgence.jaune:
        return const Color(0x22FFB572);
      case EntretienUrgence.vert:
        return const Color(0x2250D1AA);
    }
  }

  //Ajout du getter icone
  IconData get icone {
    switch (this) {
      case EntretienUrgence.rouge:
        return Icons.warning_rounded;
      case EntretienUrgence.jaune:
        return Icons.info_rounded;
      case EntretienUrgence.vert:
        return Icons.shield_rounded;
    }
  }
}

class EntretienItem {
  final String id;
  final String vehiculeId;
  final String titre;
  final TypeEcheance typeEcheance;
  final int? kmActuels;
  final int? kmEcheance;
  final int? joursRestants;
  final String? dateEcheance;

  const EntretienItem({
    required this.id,
    required this.vehiculeId,
    required this.titre,
    required this.typeEcheance,
    this.kmActuels,
    this.kmEcheance,
    this.joursRestants,
    this.dateEcheance,
  });

  EntretienUrgence get urgence {
    if (typeEcheance == TypeEcheance.km && kmActuels != null && kmEcheance != null) {
      final pct = kmActuels! / kmEcheance!;
      if (pct >= 0.9) return EntretienUrgence.rouge;
      if (pct >= 0.75) return EntretienUrgence.jaune;
      return EntretienUrgence.vert;
    } else if (typeEcheance == TypeEcheance.date && joursRestants != null) {
      if (joursRestants! <= 7) return EntretienUrgence.rouge;
      if (joursRestants! <= 30) return EntretienUrgence.jaune;
      return EntretienUrgence.vert;
    }
    return EntretienUrgence.vert;
  }

  double get progressValue {
    if (typeEcheance == TypeEcheance.km && kmActuels != null && kmEcheance != null) {
      return (kmActuels! / kmEcheance!).clamp(0.0, 1.0);
    } else if (typeEcheance == TypeEcheance.date && joursRestants != null) {
      // Pour une échéance de date, on calcule le progrès sur 365 jours
      final progress = 1 - (joursRestants! / 365);
      return progress.clamp(0.0, 1.0);
    }
    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicule_id': vehiculeId,
      'titre': titre,
      'type_echeance': typeEcheance == TypeEcheance.km ? 'km' : 'date',
      'km_actuels': kmActuels,
      'km_echeance': kmEcheance,
      'jours_restants': joursRestants,
      'date_echeance': dateEcheance,
    };
  }

  factory EntretienItem.fromMap(Map<String, dynamic> map) {
    return EntretienItem(
      id: map['id'],
      vehiculeId: map['vehicule_id'],
      titre: map['titre'],
      typeEcheance: map['type_echeance'] == 'km' ? TypeEcheance.km : TypeEcheance.date,
      kmActuels: map['km_actuels'],
      kmEcheance: map['km_echeance'],
      joursRestants: map['jours_restants'],
      dateEcheance: map['date_echeance'],
    );
  }
}

class Vehicule {
  final String id;
  final String marque;
  final String modele;
  final String immatriculation;
  final String type;
  final int chargeMaxKg;
  final double volumeM3;
  final int annee;
  final DisponibiliteVehicule disponibilite;
  final int livraisonsTotal;
  final int livraisonsMoisEnCours;
  final double kmParcourus;
  final int joursProchainEntretien;
  final DateTime dateAjout;

  const Vehicule({
    required this.id,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    required this.type,
    required this.chargeMaxKg,
    required this.volumeM3,
    required this.annee,
    required this.disponibilite,
    required this.livraisonsTotal,
    required this.livraisonsMoisEnCours,
    required this.kmParcourus,
    required this.joursProchainEntretien,
    required this.dateAjout,
  });

  String get nomComplet => '$marque $modele';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'marque': marque,
      'modele': modele,
      'immatriculation': immatriculation,
      'type': type,
      'charge_max_kg': chargeMaxKg,
      'volume_m3': volumeM3,
      'annee': annee,
      'disponibilite': disponibilite.toJson,
      'livraisons_total': livraisonsTotal,
      'livraisons_mois': livraisonsMoisEnCours,
      'km_parcourus': kmParcourus,
      'jours_entretien': joursProchainEntretien,
      'date_ajout': dateAjout.toIso8601String(),
    };
  }

  factory Vehicule.fromMap(Map<String, dynamic> map) {
    return Vehicule(
      id: map['id'],
      marque: map['marque'],
      modele: map['modele'],
      immatriculation: map['immatriculation'],
      type: map['type'],
      chargeMaxKg: map['charge_max_kg'],
      volumeM3: map['volume_m3'],
      annee: map['annee'],
      disponibilite: disponibiliteVehiculeFromJson(map['disponibilite']),
      livraisonsTotal: map['livraisons_total'],
      livraisonsMoisEnCours: map['livraisons_mois'],
      kmParcourus: map['km_parcourus'],
      joursProchainEntretien: map['jours_entretien'],
      dateAjout: DateTime.parse(map['date_ajout']),
    );
  }

  Vehicule copyWith({
    String? id,
    String? marque,
    String? modele,
    String? immatriculation,
    String? type,
    int? chargeMaxKg,
    double? volumeM3,
    int? annee,
    DisponibiliteVehicule? disponibilite,
    int? livraisonsTotal,
    int? livraisonsMoisEnCours,
    double? kmParcourus,
    int? joursProchainEntretien,
    DateTime? dateAjout,
  }) {
    return Vehicule(
      id: id ?? this.id,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      immatriculation: immatriculation ?? this.immatriculation,
      type: type ?? this.type,
      chargeMaxKg: chargeMaxKg ?? this.chargeMaxKg,
      volumeM3: volumeM3 ?? this.volumeM3,
      annee: annee ?? this.annee,
      disponibilite: disponibilite ?? this.disponibilite,
      livraisonsTotal: livraisonsTotal ?? this.livraisonsTotal,
      livraisonsMoisEnCours: livraisonsMoisEnCours ?? this.livraisonsMoisEnCours,
      kmParcourus: kmParcourus ?? this.kmParcourus,
      joursProchainEntretien: joursProchainEntretien ?? this.joursProchainEntretien,
      dateAjout: dateAjout ?? this.dateAjout,
    );
  }
}