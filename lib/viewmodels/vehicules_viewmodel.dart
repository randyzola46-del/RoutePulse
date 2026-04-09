import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicule.dart';

//State

class VehiculesState {
  final List<Vehicule> vehicules;
  final String recherche;
  final DisponibiliteVehicule? filtreDisponibilite; // null = Tous

  const VehiculesState({
    required this.vehicules,
    this.recherche = '',
    this.filtreDisponibilite,
  });

  List<Vehicule> get vehiculesFiltres {
    var list = vehicules;
    if (filtreDisponibilite != null) {
      list = list.where((v) => v.disponibilite == filtreDisponibilite).toList();
    }
    if (recherche.isNotEmpty) {
      final q = recherche.toLowerCase();
      list = list.where((v) =>
        v.nomComplet.toLowerCase().contains(q) ||
        v.immatriculation.toLowerCase().contains(q),
      ).toList();
    }
    return list;
  }

  VehiculesState copyWith({
    List<Vehicule>? vehicules,
    String? recherche,
    Object? filtreDisponibilite = _sentinel,
  }) {
    return VehiculesState(
      vehicules: vehicules ?? this.vehicules,
      recherche: recherche ?? this.recherche,
      filtreDisponibilite: filtreDisponibilite == _sentinel
          ? this.filtreDisponibilite
          : filtreDisponibilite as DisponibiliteVehicule?,
    );
  }
}

const _sentinel = Object();

//ViewModel
class VehiculesViewModel extends StateNotifier<VehiculesState> {
  VehiculesViewModel() : super(VehiculesState(vehicules: _mockVehicules));

  void setRecherche(String q) => state = state.copyWith(recherche: q);

  void setFiltreDisponibilite(DisponibiliteVehicule? f) =>
      state = state.copyWith(filtreDisponibilite: f);

  void changerDisponibilite(String id, DisponibiliteVehicule dispo) {
    if (dispo == DisponibiliteVehicule.disponible) {
      state = state.copyWith(
        vehicules: state.vehicules.map((v) {
          if (v.id == id) {
            return v.copyWith(disponibilite: DisponibiliteVehicule.disponible);
          } else {
            return v.copyWith(disponibilite: DisponibiliteVehicule.indisponible);
          }
        }).toList(),
      );
    } else {
      state = state.copyWith(
        vehicules: state.vehicules.map((v) =>
        v.id == id ? v.copyWith(disponibilite: dispo) : v,
        ).toList(),
      );
    }
  }

  void ajouterVehicule({
    required String marque,
    required String modele,
    required String immatriculation,
    required String type,
    required int chargeMaxKg,
    required double volumeM3,
    required int annee,
  }) {
    final nouveau = Vehicule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      marque: marque,
      modele: modele,
      immatriculation: immatriculation,
      type: type,
      chargeMaxKg: chargeMaxKg,
      volumeM3: volumeM3,
      annee: annee,
      disponibilite: DisponibiliteVehicule.disponible,
      livraisonsTotal: 0,
      livraisonsMoisEnCours: 0,
      kmParcourus: 0,
      joursProchainEntretien: 90,
      dernieresMissions: [],
    );
    state = state.copyWith(vehicules: [...state.vehicules, nouveau]);
  }

  void supprimerVehicule(String id) {
    state = state.copyWith(
      vehicules: state.vehicules.where((v) => v.id != id).toList(),
    );
  }
}

final vehiculesViewModelProvider =
    StateNotifierProvider<VehiculesViewModel, VehiculesState>(
  (_) => VehiculesViewModel(),
);

//Données mock
final _mockVehicules = <Vehicule>[
  Vehicule(
    id: 'v1',
    marque: 'Renault',
    modele: 'Master',
    immatriculation: 'AB-123-CD',
    type: 'Fourgon',
    chargeMaxKg: 1200,
    volumeM3: 8,
    annee: 2021,
    disponibilite: DisponibiliteVehicule.disponible,
    livraisonsTotal: 1284,
    livraisonsMoisEnCours: 12,
    kmParcourus: 42000,
    joursProchainEntretien: 18,
    dernieresMissions: [
      MissionVehicule(date: '23 mars', chauffeur: 'Jean-Pierre M.', km: 127),
      MissionVehicule(date: '22 mars', chauffeur: 'Jean-Pierre M.', km: 84),
      MissionVehicule(date: '20 mars', chauffeur: 'Jean-Pierre M.', km: 201),
      MissionVehicule(date: '18 mars', chauffeur: 'Jean-Pierre M.', km: 95),
    ],
    entretiens: [
      EntretienItem(
        titre: 'Vidange huile',
        typeEcheance: TypeEcheance.km,
        kmActuels: 42180,
        kmEcheance: 45000,
        joursRestants: 3,
      ),
      EntretienItem(
        titre: 'Contrôle technique',
        typeEcheance: TypeEcheance.date,
        joursRestants: 64,
        dateEcheance: '15 juin 2026',
      ),
      EntretienItem(
        titre: 'Révision complète',
        typeEcheance: TypeEcheance.km,
        kmActuels: 42180,
        kmEcheance: 60000,
        joursRestants: 118,
      ),
    ],
  ),
  Vehicule(
    id: 'v2',
    marque: 'Peugeot',
    modele: 'Partner',
    immatriculation: 'EF-456-GH',
    type: 'Fourgon',
    chargeMaxKg: 800,
    volumeM3: 4,
    annee: 2019,
    disponibilite: DisponibiliteVehicule.indisponible,
    livraisonsTotal: 632,
    livraisonsMoisEnCours: 5,
    kmParcourus: 28000,
    joursProchainEntretien: 42,
    dernieresMissions: [
      MissionVehicule(date: '21 mars', chauffeur: 'Sophie D.', km: 63),
      MissionVehicule(date: '19 mars', chauffeur: 'Sophie D.', km: 48),
    ],
    entretiens: [
      EntretienItem(
        titre: 'Vidange huile',
        typeEcheance: TypeEcheance.km,
        kmActuels: 28000,
        kmEcheance: 30000,
        joursRestants: 21,
      ),
      EntretienItem(
        titre: 'Contrôle technique',
        typeEcheance: TypeEcheance.date,
        joursRestants: 180,
        dateEcheance: '15 oct. 2026',
      ),
    ],
  ),
  Vehicule(
    id: 'v3',
    marque: 'Ford',
    modele: 'Transit',
    immatriculation: 'IJ-789-KL',
    type: 'Camion',
    chargeMaxKg: 2000,
    volumeM3: 14,
    annee: 2020,
    disponibilite: DisponibiliteVehicule.indisponible,
    livraisonsTotal: 420,
    livraisonsMoisEnCours: 0,
    kmParcourus: 61000,
    joursProchainEntretien: 3,
    dernieresMissions: [
      MissionVehicule(date: '10 mars', chauffeur: 'Marc L.', km: 310),
    ],
    entretiens: [
      EntretienItem(
        titre: 'Courroie de distribution',
        typeEcheance: TypeEcheance.km,
        kmActuels: 61000,
        kmEcheance: 65000,
        joursRestants: 5,
      ),
      EntretienItem(
        titre: 'Vidange huile',
        typeEcheance: TypeEcheance.km,
        kmActuels: 61000,
        kmEcheance: 75000,
        joursRestants: 90,
      ),
    ],
  ),
];
