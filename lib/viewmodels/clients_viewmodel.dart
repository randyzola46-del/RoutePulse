import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';

//State

enum FiltreClients { tous, recents, inactifs }

class ClientsState {
  final List<Client> clients;
  final String recherche;
  final FiltreClients filtre;

  const ClientsState({
    required this.clients,
    this.recherche = '',
    this.filtre = FiltreClients.tous,
  });

  List<Client> get clientsFiltres {
    var list = clients;
    if (recherche.isNotEmpty) {
      final q = recherche.toLowerCase();
      list = list.where((c) =>
        c.nomComplet.toLowerCase().contains(q) ||
        c.adresse.toLowerCase().contains(q),
      ).toList();
    }
    // Tri par livraisons décroissant (= Top clients)
    list.sort((a, b) => b.livraisonsTotal.compareTo(a.livraisonsTotal));
    return list;
  }

  ClientsState copyWith({
    List<Client>? clients,
    String? recherche,
    FiltreClients? filtre,
  }) {
    return ClientsState(
      clients: clients ?? this.clients,
      recherche: recherche ?? this.recherche,
      filtre: filtre ?? this.filtre,
    );
  }
}

//ViewModel

class ClientsViewModel extends StateNotifier<ClientsState> {
  ClientsViewModel() : super(ClientsState(clients: _mockClients));

  void setRecherche(String q) => state = state.copyWith(recherche: q);
  void setFiltre(FiltreClients f) => state = state.copyWith(filtre: f);

  void ajouterClient({
    required String prenom,
    required String nom,
    required String adresse,
  }) {
    final nouveau = Client(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      prenom: prenom,
      nom: nom,
      adresse: adresse,
      rang: RangClient.standard,
      estRecurrent: false,
      livraisonsTotal: 0,
      tauxSucces: 0,
      creneauPrefere: '—',
      historique: [],
    );
    state = state.copyWith(clients: [...state.clients, nouveau]);
  }

  void supprimerClient(String id) {
    state = state.copyWith(
      clients: state.clients.where((c) => c.id != id).toList(),
    );
  }
}

final clientsViewModelProvider =
    StateNotifierProvider<ClientsViewModel, ClientsState>(
  (_) => ClientsViewModel(),
);

//Données mock

final _mockClients = <Client>[
  Client(
    id: 'c1',
    prenom: 'Martin',
    nom: 'Dupont',
    adresse: '12 rue Carnot, Lyon',
    rang: RangClient.gold,
    estRecurrent: true,
    livraisonsTotal: 24,
    tauxSucces: 0.96,
    creneauPrefere: '14–16h',
    historique: [
      HistoriqueLivraison(date: '20 mars · 14h32', adresse: '12 rue Carnot, Lyon', statut: StatutHistorique.livree),
      HistoriqueLivraison(date: '17 mars · 15h08', adresse: '12 rue Carnot, Lyon', statut: StatutHistorique.livree),
      HistoriqueLivraison(date: '14 mars · 10h54', adresse: '12 rue Carnot, Lyon', statut: StatutHistorique.reportee),
      HistoriqueLivraison(date: '10 mars · 14h17', adresse: '12 rue Carnot, Lyon', statut: StatutHistorique.livree),
    ],
  ),
  Client(
    id: 'c2',
    prenom: 'Sophie',
    nom: 'Bernard',
    adresse: '8 av. de la Paix, Paris',
    rang: RangClient.silver,
    estRecurrent: true,
    livraisonsTotal: 18,
    tauxSucces: 0.89,
    creneauPrefere: '9–11h',
    historique: [
      HistoriqueLivraison(date: '22 mars · 09h15', adresse: '8 av. de la Paix', statut: StatutHistorique.livree),
      HistoriqueLivraison(date: '15 mars · 10h30', adresse: '8 av. de la Paix', statut: StatutHistorique.livree),
      HistoriqueLivraison(date: '08 mars · 09h50', adresse: '8 av. de la Paix', statut: StatutHistorique.echouee),
    ],
  ),
  Client(
    id: 'c3',
    prenom: 'Éric',
    nom: 'Moreau',
    adresse: '45 blvd V. Hugo, Marseille',
    rang: RangClient.bronze,
    estRecurrent: false,
    livraisonsTotal: 11,
    tauxSucces: 0.91,
    creneauPrefere: '16–18h',
    historique: [
      HistoriqueLivraison(date: '19 mars · 16h42', adresse: '45 blvd V. Hugo', statut: StatutHistorique.livree),
      HistoriqueLivraison(date: '12 mars · 17h05', adresse: '45 blvd V. Hugo', statut: StatutHistorique.livree),
    ],
  ),
  Client(
    id: 'c4',
    prenom: 'Lucie',
    nom: 'Fontaine',
    adresse: '3 impasse des Lilas, Bordeaux',
    rang: RangClient.standard,
    estRecurrent: false,
    livraisonsTotal: 4,
    tauxSucces: 1.0,
    creneauPrefere: '10–12h',
    historique: [
      HistoriqueLivraison(date: '23 mars · 10h20', adresse: '3 impasse des Lilas', statut: StatutHistorique.livree),
    ],
  ),
];
