import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../services/database_service.dart';

enum FiltreClients { tous, gold, silver, bronze, recurrents, nouveaux }

class ClientsState {
  final List<Client> clients;
  final String recherche;
  final FiltreClients filtre;
  final bool isLoading;
  final String? error;

  const ClientsState({
    this.clients = const [],
    this.recherche = '',
    this.filtre = FiltreClients.tous,
    this.isLoading = false,
    this.error,
  });

  List<Client> get clientsFiltres {
    List<Client> list = List<Client>.from(clients);

    switch (filtre) {
      case FiltreClients.gold:
        list = list.where((c) => c.rang == RangClient.gold).toList();
        break;
      case FiltreClients.silver:
        list = list.where((c) => c.rang == RangClient.silver).toList();
        break;
      case FiltreClients.bronze:
        list = list.where((c) => c.rang == RangClient.bronze).toList();
        break;
      case FiltreClients.recurrents:
        list = list.where((c) => c.estRecurrent).toList();
        break;
      case FiltreClients.nouveaux:
        list = list.where((c) => c.livraisonsTotal <= 1 && !c.estRecurrent).toList();
        break;
      case FiltreClients.tous:
        break;
    }

    if (recherche.isNotEmpty) {
      final q = recherche.toLowerCase();
      list = list.where((c) =>
      c.nomComplet.toLowerCase().contains(q) ||
          c.adresse.toLowerCase().contains(q),
      ).toList();
    }

    if (list.isNotEmpty) {
      list.sort((a, b) {
        final rangOrder = _rangPriority(a.rang).compareTo(_rangPriority(b.rang));
        if (rangOrder != 0) return rangOrder;
        return b.livraisonsTotal.compareTo(a.livraisonsTotal);
      });
    }

    return list;
  }

  int _rangPriority(RangClient rang) {
    switch (rang) {
      case RangClient.gold:
        return 0;
      case RangClient.silver:
        return 1;
      case RangClient.bronze:
        return 2;
      case RangClient.standard:
        return 3;
    }
  }

  List<Client> get topClients {
    final List<Client> list = List<Client>.from(clients);
    list.removeWhere((c) => c.rang != RangClient.gold && c.rang != RangClient.silver);
    list.sort((a, b) => b.livraisonsTotal.compareTo(a.livraisonsTotal));
    return list;
  }

  List<Client> get clientsRecurrents {
    final List<Client> list = clients.where((c) => c.estRecurrent).toList();
    list.sort((a, b) => b.livraisonsTotal.compareTo(a.livraisonsTotal));
    return list;
  }

  List<Client> get nouveauxClients {
    final List<Client> list = clients
        .where((c) => c.livraisonsTotal <= 1 && !c.estRecurrent)
        .toList();
    list.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return list;
  }

  ClientsState copyWith({
    List<Client>? clients,
    String? recherche,
    FiltreClients? filtre,
    bool? isLoading,
    String? error,
  }) {
    return ClientsState(
      clients: clients ?? this.clients,
      recherche: recherche ?? this.recherche,
      filtre: filtre ?? this.filtre,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ClientsViewModel extends StateNotifier<ClientsState> {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  ClientsViewModel() : super(const ClientsState()) {
    loadClients();
  }

  Future<void> loadClients() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final clients = await _db.getAllClients();
      state = state.copyWith(clients: clients, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void setRecherche(String q) => state = state.copyWith(recherche: q);
  void setFiltre(FiltreClients f) => state = state.copyWith(filtre: f);

  Future<void> ajouterClient({
    required String prenom,
    required String nom,
    required String adresse,
    String? notes,
  }) async {
    final nouveau = Client(
      id: _uuid.v4(),
      prenom: prenom.trim(),
      nom: nom.trim(),
      adresse: adresse.trim(),
      rang: RangClient.standard,
      estRecurrent: false,
      livraisonsTotal: 0,
      tauxSucces: 0.0,
      creneauPrefere: '09:00 - 12:00',
      dateCreation: DateTime.now(),
      notes: notes?.trim(),
    );
    await _db.insertClient(nouveau);
    await loadClients();
  }

  Future<void> modifierClient(Client client) async {
    await _db.updateClient(client);
    await loadClients();
  }

  Future<void> supprimerClient(String id) async {
    await _db.deleteClient(id);
    await loadClients();
  }
}

final clientsViewModelProvider = StateNotifierProvider<ClientsViewModel, ClientsState>(
      (_) => ClientsViewModel(),
);