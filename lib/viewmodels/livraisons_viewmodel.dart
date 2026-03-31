import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/livraison.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class LivraisonsState {
  final List<Livraison> livraisons;
  final StatutLivraison? filtreStatut;
  final String recherche;
  final bool isLoading;
  final String? erreur;

  const LivraisonsState({
    this.livraisons = const [],
    this.filtreStatut,
    this.recherche = '',
    this.isLoading = false,
    this.erreur,
  });

  List<Livraison> get livraisonsFiltrees {
    return livraisons.where((l) {
      final matchStatut =
          filtreStatut == null || l.statut == filtreStatut;
      final matchRecherche = recherche.isEmpty ||
          l.nomClient.toLowerCase().contains(recherche.toLowerCase()) ||
          l.adresse.toLowerCase().contains(recherche.toLowerCase());
      return matchStatut && matchRecherche;
    }).toList();
  }

  int get totalLivraisons => livraisons.length;
  int countParStatut(StatutLivraison s) =>
      livraisons.where((l) => l.statut == s).length;

  LivraisonsState copyWith({
    List<Livraison>? livraisons,
    StatutLivraison? Function()? filtreStatut,
    String? recherche,
    bool? isLoading,
    String? Function()? erreur,
  }) {
    return LivraisonsState(
      livraisons: livraisons ?? this.livraisons,
      filtreStatut:
          filtreStatut != null ? filtreStatut() : this.filtreStatut,
      recherche: recherche ?? this.recherche,
      isLoading: isLoading ?? this.isLoading,
      erreur: erreur != null ? erreur() : this.erreur,
    );
  }
}

//ViewModel

class LivraisonsViewModel extends StateNotifier<LivraisonsState> {
  LivraisonsViewModel() : super(const LivraisonsState()) {
    _chargerDonneesInitiales();
  }

  final _uuid = const Uuid();

  // SEED de données pour la démo
  void _chargerDonneesInitiales() {
    final seed = [
      Livraison(
        id: _uuid.v4(),
        nomClient: 'Martin Dupont',
        adresse: '12 rue Carnot, Lyon 69002',
        creneau: '14h – 16h',
        nbColis: 3,
        poids: 12.5,
        statut: StatutLivraison.enCours,
        notes: 'Sonner 2 fois',
        dateCreation: DateTime.now(),
      ),
      Livraison(
        id: _uuid.v4(),
        nomClient: 'Sophie Bernard',
        adresse: '8 av. de la Paix, Lyon 69006',
        creneau: '16h – 18h',
        nbColis: 1,
        poids: 4.0,
        statut: StatutLivraison.enAttente,
        dateCreation: DateTime.now(),
      ),
      Livraison(
        id: _uuid.v4(),
        nomClient: 'Éric Moreau',
        adresse: '45 blvd Victor Hugo, Lyon 69003',
        creneau: '10h – 12h',
        nbColis: 2,
        poids: 7.8,
        statut: StatutLivraison.livree,
        dateCreation: DateTime.now(),
      ),
      Livraison(
        id: _uuid.v4(),
        nomClient: 'Claire Petit',
        adresse: '3 place Bellecour, Lyon 69002',
        creneau: '09h – 11h',
        nbColis: 5,
        poids: 22.0,
        statut: StatutLivraison.annulee,
        notes: 'Client absent',
        dateCreation: DateTime.now(),
      ),
    ];
    state = state.copyWith(livraisons: seed);
  }

  //CREATE
  void ajouterLivraison({
    required String nomClient,
    required String adresse,
    required String creneau,
    required int nbColis,
    required double poids,
    String? notes,
  }) {
    final nouvelle = Livraison(
      id: _uuid.v4(),
      nomClient: nomClient,
      adresse: adresse,
      creneau: creneau,
      nbColis: nbColis,
      poids: poids,
      statut: StatutLivraison.enAttente,
      notes: notes,
      dateCreation: DateTime.now(),
    );
    state = state.copyWith(
      livraisons: [...state.livraisons, nouvelle],
    );
  }

  //UPDATE

  void modifierLivraison(Livraison livraison) {
    state = state.copyWith(
      livraisons: state.livraisons
          .map((l) => l.id == livraison.id ? livraison : l)
          .toList(),
    );
  }

  void changerStatut(String id, StatutLivraison nouveauStatut) {
    state = state.copyWith(
      livraisons: state.livraisons
          .map((l) => l.id == id ? l.copyWith(statut: nouveauStatut) : l)
          .toList(),
    );
  }

  //DELETE

  void supprimerLivraison(String id) {
    state = state.copyWith(
      livraisons: state.livraisons.where((l) => l.id != id).toList(),
    );
  }

  //FILTRES / RECHERCHE

  void setFiltreStatut(StatutLivraison? statut) {
    state = state.copyWith(filtreStatut: () => statut);
  }

  void setRecherche(String query) {
    state = state.copyWith(recherche: query);
  }
}

//Provider

final livraisonsViewModelProvider =
    StateNotifierProvider<LivraisonsViewModel, LivraisonsState>(
  (ref) => LivraisonsViewModel(),
);
