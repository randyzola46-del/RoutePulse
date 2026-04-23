// lib/viewmodels/vehicules_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicule.dart';
import '../services/app_database_service.dart';
import 'livraisons_viewmodel.dart';

class VehiculesState {
  final List<Vehicule> vehicules;
  final String recherche;
  final DisponibiliteVehicule? filtreDisponibilite;
  final bool isLoading;
  final String? error;

  const VehiculesState({
    this.vehicules = const [],
    this.recherche = '',
    this.filtreDisponibilite,
    this.isLoading = false,
    this.error,
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
    Object? filtreDisponibilite,
    bool? isLoading,
    String? error,
  }) {
    return VehiculesState(
      vehicules: vehicules ?? this.vehicules,
      recherche: recherche ?? this.recherche,
      filtreDisponibilite: filtreDisponibilite == _sentinel
          ? this.filtreDisponibilite
          : filtreDisponibilite as DisponibiliteVehicule?,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

const _sentinel = Object();

class VehiculesViewModel extends StateNotifier<VehiculesState> {
  final Ref _ref;
  final AppDatabaseService _db = AppDatabaseService();
  final Uuid _uuid = const Uuid();

  VehiculesViewModel(this._ref) : super(const VehiculesState()) {
    chargerVehicules();
  }

  Future<void> chargerVehicules() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final vehicules = await _db.getAllVehicules();
      state = state.copyWith(vehicules: vehicules, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void setRecherche(String q) => state = state.copyWith(recherche: q);
  void setFiltreDisponibilite(DisponibiliteVehicule? f) =>
      state = state.copyWith(filtreDisponibilite: f);

  Future<void> changerDisponibilite(String id, DisponibiliteVehicule dispo, {bool autoAssignLivraisons = true}) async {
    final vehicule = state.vehicules.firstWhere((v) => v.id == id);
    final ancienneDispo = vehicule.disponibilite;
    final updated = vehicule.copyWith(disponibilite: dispo);
    await _db.updateVehicule(updated);
    await chargerVehicules();

    if (autoAssignLivraisons) {
      final livraisonsVM = _ref.read(livraisonsViewModelProvider.notifier);
      if (dispo == DisponibiliteVehicule.disponible && ancienneDispo == DisponibiliteVehicule.indisponible) {
      } else if (dispo == DisponibiliteVehicule.indisponible && ancienneDispo == DisponibiliteVehicule.disponible) {
      }
    }
  }

  Future<void> ajouterVehicule({
    required String marque,
    required String modele,
    required String immatriculation,
    required String type,
    required int chargeMaxKg,
    required double volumeM3,
    required int annee,
  }) async {
    final nouveau = Vehicule(
      id: _uuid.v4(),
      marque: marque,
      modele: modele,
      immatriculation: immatriculation,
      type: type,
      chargeMaxKg: chargeMaxKg,
      volumeM3: volumeM3,
      annee: annee,
      disponibilite: DisponibiliteVehicule.indisponible,
      livraisonsTotal: 0,
      livraisonsMoisEnCours: 0,
      kmParcourus: 0,
      joursProchainEntretien: 90,
      dateAjout: DateTime.now(),
    );
    await _db.insertVehicule(nouveau);
    await chargerVehicules();
  }

  Future<void> modifierVehicule(Vehicule vehicule) async {
    await _db.updateVehicule(vehicule);
    await chargerVehicules();
  }

  Future<void> supprimerVehicule(String id) async {
    await _db.deleteVehicule(id);
    await chargerVehicules();
  }
}

final vehiculesViewModelProvider = StateNotifierProvider<VehiculesViewModel, VehiculesState>(
      (ref) => VehiculesViewModel(ref),
);