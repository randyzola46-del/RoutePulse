enum DisponibiliteVehicule { disponible, indisponible }

//Entretien

enum TypeEcheance { km, date }

class EntretienItem {
  final String titre;
  final TypeEcheance typeEcheance;

  // Pour les échéances en km
  final int? kmActuels;
  final int? kmEcheance;

  // Pour les échéances en date (jours restants)
  final int? joursRestants;
  final String? dateEcheance; // ex: "15 juin 2026"

  // Urgence calculée automatiquement
  EntretienUrgence get urgence {
    if (typeEcheance == TypeEcheance.km && kmActuels != null && kmEcheance != null) {
      final kmRestants = kmEcheance! - kmActuels!;
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
      // On suppose max 365 jours pour la progressbar
      return (1 - joursRestants! / 365).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  const EntretienItem({
    required this.titre,
    required this.typeEcheance,
    this.kmActuels,
    this.kmEcheance,
    this.joursRestants,
    this.dateEcheance,
  });
}

enum EntretienUrgence { rouge, jaune, vert }

extension DisponibiliteVehiculeX on DisponibiliteVehicule {
  String get label {
    switch (this) {
      case DisponibiliteVehicule.disponible:    return 'Disponible';
      case DisponibiliteVehicule.indisponible:  return 'Indisponible';
    }
  }
}

class Vehicule {
  final String id;
  final String marque;
  final String modele;
  final String immatriculation;
  final String type; // Fourgon, Camion, Autre
  final int chargeMaxKg;
  final double volumeM3;
  final int annee;
  final DisponibiliteVehicule disponibilite;
  final int livraisonsTotal;
  final int livraisonsMoisEnCours;
  final double kmParcourus;
  final int joursProchainEntretien;
  final List<MissionVehicule> dernieresMissions;
  final List<EntretienItem> entretiens;

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
    required this.dernieresMissions,
    this.entretiens = const [],
  });

  String get nomComplet => '$marque $modele';

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
    List<MissionVehicule>? dernieresMissions,
    List<EntretienItem>? entretiens,
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
      dernieresMissions: dernieresMissions ?? this.dernieresMissions,
      entretiens: entretiens ?? this.entretiens,
    );
  }
}

class MissionVehicule {
  final String date;
  final String chauffeur;
  final double km;

  const MissionVehicule({
    required this.date,
    required this.chauffeur,
    required this.km,
  });
}
