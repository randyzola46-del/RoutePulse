// lib/viewmodels/livraisons_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../models/livraison.dart';
import '../models/vehicule.dart';
import '../services/app_database_service.dart';
import 'clients_viewmodel.dart';
import 'vehicules_viewmodel.dart';

enum TriLivraisons { urgent, recent, priorite }

class LivraisonsState {
  final List<Livraison> livraisons;
  final StatutLivraison? filtreStatut;
  final String recherche;
  final bool isLoading;
  final String? erreur;
  final TriLivraisons tri;
  final Set<String> vehiculesAvecMissionActive;
  final bool isSubmitting;

  const LivraisonsState({
    this.livraisons = const [],
    this.filtreStatut,
    this.recherche = '',
    this.isLoading = false,
    this.erreur,
    this.tri = TriLivraisons.priorite,
    this.vehiculesAvecMissionActive = const {},
    this.isSubmitting = false,
  });

  List<Livraison> get livraisonsFiltrees {
    var list = livraisons.where((l) {
      final matchStatut = filtreStatut == null || l.statut == filtreStatut;
      final matchRecherche = recherche.isEmpty ||
          l.nomClient.toLowerCase().contains(recherche.toLowerCase()) ||
          l.adresse.toLowerCase().contains(recherche.toLowerCase());
      return matchStatut && matchRecherche;
    }).toList();

    switch (tri) {
      case TriLivraisons.urgent:
        list.sort((a, b) => a.creneau.compareTo(b.creneau));
        break;
      case TriLivraisons.recent:
        list.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
        break;
      case TriLivraisons.priorite:
        list.sort((a, b) {
          if (a.statut == StatutLivraison.enCours && b.statut != StatutLivraison.enCours) return -1;
          if (b.statut == StatutLivraison.enCours && a.statut != StatutLivraison.enCours) return 1;
          if (a.statut == StatutLivraison.enAttente && b.statut != StatutLivraison.enAttente) return -1;
          if (b.statut == StatutLivraison.enAttente && a.statut != StatutLivraison.enAttente) return 1;
          return b.dateCreation.compareTo(a.dateCreation);
        });
        break;
    }
    return list;
  }

  int get totalLivraisons => livraisons.length;
  int countParStatut(StatutLivraison s) => livraisons.where((l) => l.statut == s).length;

  LivraisonsState copyWith({
    List<Livraison>? livraisons,
    StatutLivraison? filtreStatut,
    String? recherche,
    bool? isLoading,
    String? erreur,
    TriLivraisons? tri,
    Set<String>? vehiculesAvecMissionActive,
    bool? isSubmitting,
  }) {
    return LivraisonsState(
      livraisons: livraisons ?? this.livraisons,
      filtreStatut: filtreStatut ?? this.filtreStatut,
      recherche: recherche ?? this.recherche,
      isLoading: isLoading ?? this.isLoading,
      erreur: erreur ?? this.erreur,
      tri: tri ?? this.tri,
      vehiculesAvecMissionActive: vehiculesAvecMissionActive ?? this.vehiculesAvecMissionActive,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class LivraisonsViewModel extends StateNotifier<LivraisonsState> {
  final Ref _ref;
  final AppDatabaseService _db = AppDatabaseService();
  final Uuid _uuid = const Uuid();
  final Map<String, List<String>> _livraisonsEnCoursParVehicule = {};

  bool _isAdding = false;
  bool _isLoading = false;
  DateTime _lastLoadTime = DateTime.now().subtract(const Duration(seconds: 10));
  List<Livraison> _lastLoadedLivraisons = [];

  LivraisonsViewModel(this._ref) : super(const LivraisonsState()) {
    _initAvecUtilisateur();
  }

  Future<void> _initAvecUtilisateur() async {
    if (_isLoading) return;
    _isLoading = true;

    final userId = await AppDatabaseService().getCurrentUserId();
    if (userId != null) {
      await chargerLivraisons();
    }

    _isLoading = false;
  }

  Future<void> chargerLivraisons() async {
    if (_isLoading || state.isLoading) return;

    final now = DateTime.now();
    if (now.difference(_lastLoadTime) < const Duration(seconds: 2)) {
      print('⏳ Chargement trop fréquent, ignoré');
      return;
    }
    _lastLoadTime = now;

    final userId = await AppDatabaseService().getCurrentUserId();
    if (userId == null) {
      print('⚠️ Aucun utilisateur connecté, chargement des livraisons ignoré');
      return;
    }

    _isLoading = true;
    state = state.copyWith(isLoading: true);

    try {
      final livraisons = await _db.getAllLivraisons();
      print('📦 Livraisons chargées: ${livraisons.length}');

      if (_areLivraisonsEqual(_lastLoadedLivraisons, livraisons)) {
        print('📦 Pas de changement, skip update');
        state = state.copyWith(isLoading: false);
        _isLoading = false;
        return;
      }

      _lastLoadedLivraisons = List.from(livraisons);
      state = state.copyWith(
        livraisons: livraisons,
        isLoading: false,
        erreur: null,
      );
      _reinitialiserMissionsEnCours();
    } catch (e) {
      print('❌ Erreur chargement livraisons: $e');
      state = state.copyWith(erreur: e.toString(), isLoading: false);
    } finally {
      _isLoading = false;
    }
  }

  bool _areLivraisonsEqual(List<Livraison> a, List<Livraison> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].statut != b[i].statut ||
          a[i].vehiculeId != b[i].vehiculeId) {
        return false;
      }
    }
    return true;
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    await chargerLivraisons();
  }

  void _reinitialiserMissionsEnCours() {
    _livraisonsEnCoursParVehicule.clear();
    for (final livraison in state.livraisons) {
      if (livraison.vehiculeId != null && livraison.statut == StatutLivraison.enCours) {
        _livraisonsEnCoursParVehicule
            .putIfAbsent(livraison.vehiculeId!, () => [])
            .add(livraison.id);
      }
    }
    final actifs = _livraisonsEnCoursParVehicule.keys.toSet();
    state = state.copyWith(vehiculesAvecMissionActive: actifs);
  }

  Future<Client> _getOrCreateClient({
    required String nomClient,
    required String adresse,
  }) async {
    print('🔍 Recherche/création client: $nomClient');

    final parts = nomClient.trim().split(' ');
    String prenom = parts.first;
    String nom = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final clientsExistants = await _db.getAllClients();

    Client? clientExistant;
    for (final c in clientsExistants) {
      if (c.nomComplet.toLowerCase() == nomClient.toLowerCase()) {
        clientExistant = c;
        print('  Client trouvé: ${c.nomComplet}');
        break;
      }
    }

    if (clientExistant != null) {
      return clientExistant;
    }

    print('  Création nouveau client...');
    final nouveauClient = Client(
      id: _uuid.v4(),
      prenom: prenom,
      nom: nom,
      adresse: adresse,
      rang: RangClient.standard,
      estRecurrent: false,
      livraisonsTotal: 1,
      tauxSucces: 0,
      creneauPrefere: '09:00 - 12:00',
      dateCreation: DateTime.now(),
      notes: 'Client créé automatiquement lors de la première livraison',
    );

    await _db.insertClient(nouveauClient);
    print('  ✅ Nouveau client créé: ${nouveauClient.id}');

    final clientsVM = _ref.read(clientsViewModelProvider.notifier);
    await clientsVM.loadClients();

    return nouveauClient;
  }

  RangClient _calculerRang(int livraisonsTotal) {
    if (livraisonsTotal >= 30) return RangClient.gold;
    if (livraisonsTotal >= 15) return RangClient.silver;
    if (livraisonsTotal >= 5) return RangClient.bronze;
    return RangClient.standard;
  }

  bool _estRecurrent(int livraisonsTotal) {
    return livraisonsTotal >= 3;
  }

  Future<void> _mettreAJourClientApresLivraison(String clientId) async {
    final client = await _db.getClient(clientId);
    if (client == null) return;

    final livraisonsClient = await _db.getLivraisonsByClient(clientId);
    final livrees = livraisonsClient.where((l) => l.statut == StatutLivraison.livree).length;
    final total = livraisonsClient.length;
    final nouveauTaux = total > 0 ? livrees / total : 0.0;

    final clientMisAJour = client.copyWith(
      livraisonsTotal: total,
      tauxSucces: nouveauTaux,
      rang: _calculerRang(total),
      estRecurrent: _estRecurrent(total),
    );

    await _db.updateClient(clientMisAJour);
    final clientsVM = _ref.read(clientsViewModelProvider.notifier);
    await clientsVM.loadClients();
  }

  Future<void> ajouterLivraison({
    required String nomClient,
    required String adresse,
    required String creneau,
    required int nbColis,
    required double poids,
    String? notes,
    String? vehiculeId,
  }) async {
    if (_isAdding || state.isSubmitting) {
      print('⏳ Déjà en cours d\'ajout, ignoré');
      return;
    }

    _isAdding = true;
    state = state.copyWith(isSubmitting: true);

    print('➕ Ajout livraison: $nomClient');

    try {
      final client = await _getOrCreateClient(
        nomClient: nomClient,
        adresse: adresse,
      );

      final nouvelle = Livraison(
        id: _uuid.v4(),
        clientId: client.id,
        nomClient: nomClient,
        adresse: adresse,
        creneau: creneau,
        nbColis: nbColis,
        poids: poids,
        statut: StatutLivraison.enAttente,
        notes: notes,
        dateCreation: DateTime.now(),
        vehiculeId: vehiculeId,
      );

      await _db.insertLivraison(nouvelle);
      print('✅ Livraison insérée: ${nouvelle.id}');

      await _mettreAJourClientApresLivraison(client.id);

      final clientsVM = _ref.read(clientsViewModelProvider.notifier);
      await clientsVM.loadClients();

      _lastLoadTime = DateTime.now().subtract(const Duration(seconds: 3));
      await chargerLivraisons();

    } catch (e) {
      print('❌ Erreur lors de l\'ajout: $e');
      state = state.copyWith(erreur: e.toString());
    } finally {
      _isAdding = false;
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> modifierLivraison(Livraison livraison) async {
    print('✏️ Modification livraison: ${livraison.id}');
    await _db.updateLivraison(livraison);
    _lastLoadTime = DateTime.now().subtract(const Duration(seconds: 3));
    await chargerLivraisons();
  }

  Future<void> changerStatut(String id, StatutLivraison nouveauStatut) async {
    final livraison = state.livraisons.firstWhere((l) => l.id == id);
    final ancienStatut = livraison.statut;
    final vehiculeId = livraison.vehiculeId;
    final updated = livraison.copyWith(statut: nouveauStatut);

    await _db.updateLivraison(updated);

    if (ancienStatut != StatutLivraison.livree && nouveauStatut == StatutLivraison.livree) {
      await _mettreAJourClientApresLivraison(livraison.clientId);
    }

    _lastLoadTime = DateTime.now().subtract(const Duration(seconds: 3));
    await chargerLivraisons();

    if (vehiculeId == null) return;

    if (ancienStatut == StatutLivraison.enAttente && nouveauStatut == StatutLivraison.enCours) {
      _demarrerMission(vehiculeId, id);
    } else if (ancienStatut == StatutLivraison.enCours &&
        (nouveauStatut == StatutLivraison.livree ||
            nouveauStatut == StatutLivraison.annulee ||
            nouveauStatut == StatutLivraison.aReporter)) {
      _retirerLivraisonEnCours(vehiculeId, id);
    }
  }

  Future<void> changerStatutAvecNote(String id, StatutLivraison nouveauStatut, String note) async {
    final livraison = state.livraisons.firstWhere((l) => l.id == id);
    final ancienStatut = livraison.statut;
    final vehiculeId = livraison.vehiculeId;
    final updated = livraison.copyWith(statut: nouveauStatut, notes: note);

    await _db.updateLivraison(updated);

    _lastLoadTime = DateTime.now().subtract(const Duration(seconds: 3));
    await chargerLivraisons();

    if (vehiculeId == null) return;

    if (ancienStatut == StatutLivraison.enCours &&
        (nouveauStatut == StatutLivraison.annulee ||
            nouveauStatut == StatutLivraison.aReporter)) {
      _retirerLivraisonEnCours(vehiculeId, id);
    }
  }

  void _demarrerMission(String vehiculeId, String livraisonId) {
    _livraisonsEnCoursParVehicule.putIfAbsent(vehiculeId, () => []).add(livraisonId);
    state = state.copyWith(vehiculesAvecMissionActive: {...state.vehiculesAvecMissionActive, vehiculeId});
  }

  void _retirerLivraisonEnCours(String vehiculeId, String livraisonId) {
    if (!_livraisonsEnCoursParVehicule.containsKey(vehiculeId)) return;
    _livraisonsEnCoursParVehicule[vehiculeId]!.remove(livraisonId);
    if (_livraisonsEnCoursParVehicule[vehiculeId]!.isEmpty) {
      _livraisonsEnCoursParVehicule.remove(vehiculeId);
      state = state.copyWith(
        vehiculesAvecMissionActive: state.vehiculesAvecMissionActive
            .where((id) => id != vehiculeId)
            .toSet(),
      );
      _rendreVehiculeDisponible(vehiculeId);
    }
  }

  Future<void> _rendreVehiculeDisponible(String vehiculeId) async {
    final vehiculesVM = _ref.read(vehiculesViewModelProvider.notifier);
    final aEncoreDesLivraisonsEnCours = state.livraisons.any(
          (l) => l.vehiculeId == vehiculeId && l.statut == StatutLivraison.enCours,
    );
    if (!aEncoreDesLivraisonsEnCours) {
      final vehicule = await _db.getVehicule(vehiculeId);
      if (vehicule != null) {
        await vehiculesVM.changerDisponibilite(vehiculeId, DisponibiliteVehicule.disponible, autoAssignLivraisons: false);
      }
    }
  }

  Future<void> assignerVehiculeLivraison(String livraisonId, String vehiculeId) async {
    final livraison = state.livraisons.firstWhere((l) => l.id == livraisonId);
    final updated = livraison.copyWith(vehiculeId: vehiculeId);
    await _db.updateLivraison(updated);
    _lastLoadTime = DateTime.now().subtract(const Duration(seconds: 3));
    await chargerLivraisons();
    if (updated.statut == StatutLivraison.enCours) {
      _demarrerMission(vehiculeId, livraisonId);
    }
  }

  Future<void> supprimerLivraison(String id) async {
    final livraison = state.livraisons.firstWhere((l) => l.id == id);
    if (livraison.statut == StatutLivraison.enCours && livraison.vehiculeId != null) {
      _retirerLivraisonEnCours(livraison.vehiculeId!, id);
    }
    await _db.deleteLivraison(id);
    _lastLoadTime = DateTime.now().subtract(const Duration(seconds: 3));
    await chargerLivraisons();
  }

  void setFiltreStatut(StatutLivraison? statut) {
    if (state.filtreStatut == statut) return;
    state = state.copyWith(filtreStatut: statut);
  }

  void setRecherche(String query) {
    if (state.recherche == query) return;
    state = state.copyWith(recherche: query);
  }

  void setTri(TriLivraisons tri) {
    if (state.tri == tri) return;
    state = state.copyWith(tri: tri);
  }

  bool hasMissionEnCours(String vehiculeId) {
    return state.vehiculesAvecMissionActive.contains(vehiculeId);
  }
}

final livraisonsViewModelProvider = StateNotifierProvider<LivraisonsViewModel, LivraisonsState>(
      (ref) => LivraisonsViewModel(ref),
);