import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/livraison.dart';
import '../models/vehicule.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'routepulse.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        prenom TEXT NOT NULL,
        nom TEXT NOT NULL,
        adresse TEXT NOT NULL,
        rang TEXT NOT NULL,
        est_recurrent INTEGER NOT NULL,
        livraisons_total INTEGER NOT NULL DEFAULT 0,
        taux_succes REAL NOT NULL DEFAULT 0,
        creneau_prefere TEXT NOT NULL,
        date_creation TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE livraisons (
        id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        nom_client TEXT NOT NULL,
        adresse TEXT NOT NULL,
        creneau TEXT NOT NULL,
        nb_colis INTEGER NOT NULL,
        poids REAL NOT NULL,
        statut TEXT NOT NULL,
        notes TEXT,
        date_creation TEXT NOT NULL,
        vehicule_id TEXT,
        historique_id TEXT,
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE vehicules (
        id TEXT PRIMARY KEY,
        marque TEXT NOT NULL,
        modele TEXT NOT NULL,
        immatriculation TEXT NOT NULL,
        type TEXT NOT NULL,
        charge_max_kg INTEGER NOT NULL,
        volume_m3 REAL NOT NULL,
        annee INTEGER NOT NULL,
        disponibilite TEXT NOT NULL,
        livraisons_total INTEGER NOT NULL DEFAULT 0,
        livraisons_mois INTEGER NOT NULL DEFAULT 0,
        km_parcourus REAL NOT NULL DEFAULT 0,
        jours_entretien INTEGER NOT NULL DEFAULT 0,
        date_ajout TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE historique (
        id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        date TEXT NOT NULL,
        adresse TEXT NOT NULL,
        statut TEXT NOT NULL,
        livraison_id TEXT,
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE entretiens (
        id TEXT PRIMARY KEY,
        vehicule_id TEXT NOT NULL,
        titre TEXT NOT NULL,
        type_echeance TEXT NOT NULL,
        km_actuels INTEGER,
        km_echeance INTEGER,
        jours_restants INTEGER,
        date_echeance TEXT,
        FOREIGN KEY (vehicule_id) REFERENCES vehicules (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_livraisons_client ON livraisons(client_id)');
    await db.execute('CREATE INDEX idx_livraisons_statut ON livraisons(statut)');
    await db.execute('CREATE INDEX idx_livraisons_vehicule ON livraisons(vehicule_id)');
    await db.execute('CREATE INDEX idx_historique_client ON historique(client_id)');

    await _insertDemoData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE clients ADD COLUMN notes TEXT');
    }
  }

  Future<void> _insertDemoData(Database db) async {
    // CLIENTS MALGACHES
    final clients = [
      Client(
        id: 'c1',
        prenom: 'Rivo',
        nom: 'Rakoto',
        adresse: 'Andraharo, Antananarivo 101',
        rang: RangClient.gold,
        estRecurrent: true,
        livraisonsTotal: 47,
        tauxSucces: 0.98,
        creneauPrefere: '09:00 - 11:00',
        dateCreation: DateTime.now().subtract(const Duration(days: 180)),
        notes: 'Client VIP - Livraison prioritaire',
      ),
      Client(
        id: 'c2',
        prenom: 'Miora',
        nom: 'Razafindramboa',
        adresse: 'Ampasampito, Antananarivo 102',
        rang: RangClient.gold,
        estRecurrent: true,
        livraisonsTotal: 38,
        tauxSucces: 0.95,
        creneauPrefere: '10:00 - 12:00',
        dateCreation: DateTime.now().subtract(const Duration(days: 150)),
        notes: 'Boutique de vêtements - Réceptionniste présent',
      ),
      Client(
        id: 'c3',
        prenom: 'Tahina',
        nom: 'Andriamanantena',
        adresse: 'Tanjombato, Antananarivo 102',
        rang: RangClient.silver,
        estRecurrent: true,
        livraisonsTotal: 29,
        tauxSucces: 0.92,
        creneauPrefere: '14:00 - 16:00',
        dateCreation: DateTime.now().subtract(const Duration(days: 120)),
      ),
      Client(
        id: 'c4',
        prenom: 'Lanto',
        nom: 'Rasolofonirina',
        adresse: 'Andranomena, Mahajanga 401',
        rang: RangClient.silver,
        estRecurrent: false,
        livraisonsTotal: 18,
        tauxSucces: 0.89,
        creneauPrefere: '08:00 - 10:00',
        dateCreation: DateTime.now().subtract(const Duration(days: 90)),
      ),
      Client(
        id: 'c5',
        prenom: 'Voahangy',
        nom: 'Rakotomalala',
        adresse: 'Tsaralalana, Antananarivo 101',
        rang: RangClient.bronze,
        estRecurrent: true,
        livraisonsTotal: 15,
        tauxSucces: 0.87,
        creneauPrefere: '15:00 - 17:00',
        dateCreation: DateTime.now().subtract(const Duration(days: 80)),
      ),
      Client(
        id: 'c6',
        prenom: 'Nantenaina',
        nom: 'Randrianasolo',
        adresse: 'Ambohimanarina, Antananarivo 101',
        rang: RangClient.bronze,
        estRecurrent: false,
        livraisonsTotal: 12,
        tauxSucces: 0.83,
        creneauPrefere: '11:00 - 13:00',
        dateCreation: DateTime.now().subtract(const Duration(days: 60)),
      ),
      Client(
        id: 'c7',
        prenom: 'Fitia',
        nom: 'Rakotozafy',
        adresse: 'Ambatobe, Antananarivo 102',
        rang: RangClient.standard,
        estRecurrent: false,
        livraisonsTotal: 8,
        tauxSucces: 1.0,
        creneauPrefere: '13:00 - 15:00',
        dateCreation: DateTime.now().subtract(const Duration(days: 45)),
      ),
      Client(
        id: 'c8',
        prenom: 'Mahery',
        nom: 'Razafimandimby',
        adresse: 'Andraisoro, Antananarivo 101',
        rang: RangClient.standard,
        estRecurrent: true,
        livraisonsTotal: 22,
        tauxSucces: 0.91,
        creneauPrefere: '09:00 - 11:00',
        dateCreation: DateTime.now().subtract(const Duration(days: 100)),
      ),
      Client(
        id: 'c9',
        prenom: 'Hary',
        nom: 'Rakotondrabe',
        adresse: 'Ankadindramamy, Antananarivo 101',
        rang: RangClient.silver,
        estRecurrent: true,
        livraisonsTotal: 25,
        tauxSucces: 0.96,
        creneauPrefere: '16:00 - 18:00',
        dateCreation: DateTime.now().subtract(const Duration(days: 110)),
      ),
      Client(
        id: 'c10',
        prenom: 'Tiavina',
        nom: 'Randrianarivelo',
        adresse: 'Ankadifotsy, Antananarivo 102',
        rang: RangClient.bronze,
        estRecurrent: false,
        livraisonsTotal: 9,
        tauxSucces: 0.78,
        creneauPrefere: '10:00 - 12:00',
        dateCreation: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];

    for (final client in clients) {
      await db.insert('clients', client.toMap());
    }

    // VÉHICULES
    final vehicules = [
      Vehicule(
        id: 'v1',
        marque: 'Honda',
        modele: 'Gold Wing',
        immatriculation: '1056-TA',
        type: 'Moto',
        chargeMaxKg: 130,
        volumeM3: 0.15,
        annee: 2023,
        disponibilite: DisponibiliteVehicule.disponible,
        livraisonsTotal: 284,
        livraisonsMoisEnCours: 18,
        kmParcourus: 15280,
        joursProchainEntretien: 25,
        dateAjout: DateTime.now().subtract(const Duration(days: 365)),
      ),
      Vehicule(
        id: 'v2',
        marque: 'Peugeot',
        modele: 'Partner',
        immatriculation: '2345-TA',
        type: 'Fourgon',
        chargeMaxKg: 800,
        volumeM3: 4.2,
        annee: 2019,
        disponibilite: DisponibiliteVehicule.disponible,
        livraisonsTotal: 432,
        livraisonsMoisEnCours: 22,
        kmParcourus: 48920,
        joursProchainEntretien: 12,
        dateAjout: DateTime.now().subtract(const Duration(days: 500)),
      ),
      Vehicule(
        id: 'v3',
        marque: 'Renault',
        modele: 'Kangoo',
        immatriculation: '7890-TA',
        type: 'Fourgon',
        chargeMaxKg: 650,
        volumeM3: 3.5,
        annee: 2021,
        disponibilite: DisponibiliteVehicule.disponible,
        livraisonsTotal: 198,
        livraisonsMoisEnCours: 12,
        kmParcourus: 28450,
        joursProchainEntretien: 35,
        dateAjout: DateTime.now().subtract(const Duration(days: 200)),
      ),
      Vehicule(
        id: 'v4',
        marque: 'Toyota',
        modele: 'Hilux',
        immatriculation: '4567-TA',
        type: 'Camionnette',
        chargeMaxKg: 1200,
        volumeM3: 2.8,
        annee: 2022,
        disponibilite: DisponibiliteVehicule.indisponible,
        livraisonsTotal: 156,
        livraisonsMoisEnCours: 8,
        kmParcourus: 35200,
        joursProchainEntretien: 5,
        dateAjout: DateTime.now().subtract(const Duration(days: 300)),
      ),
    ];

    for (final vehicule in vehicules) {
      await db.insert('vehicules', vehicule.toMap());
    }

    // ENTRETIENS
    final entretiens = [
      EntretienItem(
        id: 'e1',
        vehiculeId: 'v1',
        titre: 'Vidange huile',
        typeEcheance: TypeEcheance.km,
        kmActuels: 15280,
        kmEcheance: 18000,
      ),
      EntretienItem(
        id: 'e2',
        vehiculeId: 'v1',
        titre: 'Pneumatiques',
        typeEcheance: TypeEcheance.km,
        kmActuels: 15280,
        kmEcheance: 20000,
      ),
      EntretienItem(
        id: 'e3',
        vehiculeId: 'v2',
        titre: 'Courroie de distribution',
        typeEcheance: TypeEcheance.km,
        kmActuels: 48920,
        kmEcheance: 60000,
      ),
      EntretienItem(
        id: 'e4',
        vehiculeId: 'v2',
        titre: 'Vidange huile',
        typeEcheance: TypeEcheance.km,
        kmActuels: 48920,
        kmEcheance: 50000,
      ),
      EntretienItem(
        id: 'e5',
        vehiculeId: 'v2',
        titre: 'Contrôle technique',
        typeEcheance: TypeEcheance.date,
        joursRestants: 45,
        dateEcheance: '15 Juin 2026',
      ),
      EntretienItem(
        id: 'e6',
        vehiculeId: 'v3',
        titre: 'Vidange huile',
        typeEcheance: TypeEcheance.km,
        kmActuels: 28450,
        kmEcheance: 30000,
      ),
      EntretienItem(
        id: 'e7',
        vehiculeId: 'v3',
        titre: 'Filtre à air',
        typeEcheance: TypeEcheance.km,
        kmActuels: 28450,
        kmEcheance: 35000,
      ),
      EntretienItem(
        id: 'e8',
        vehiculeId: 'v4',
        titre: 'Vidange boîte',
        typeEcheance: TypeEcheance.km,
        kmActuels: 35200,
        kmEcheance: 40000,
      ),
      EntretienItem(
        id: 'e9',
        vehiculeId: 'v4',
        titre: 'Plaquettes frein',
        typeEcheance: TypeEcheance.km,
        kmActuels: 35200,
        kmEcheance: 38000,
      ),
    ];

    for (final entretien in entretiens) {
      await db.insert('entretiens', entretien.toMap());
    }

    final now = DateTime.now();

    final livraisons = [
      Livraison(
        id: 'l1',
        clientId: 'c1',
        nomClient: 'Rivo Rakoto',
        adresse: 'Andraharo, Antananarivo 101',
        creneau: '09:00 - 11:00',
        nbColis: 3,
        poids: 12.5,
        statut: StatutLivraison.enCours,
        notes: 'Sonner à la grille verte',
        dateCreation: now.subtract(const Duration(hours: 2)),
        vehiculeId: 'v1',
      ),
      Livraison(
        id: 'l2',
        clientId: 'c3',
        nomClient: 'Tahina Andriamanantena',
        adresse: 'Tanjombato, Antananarivo 102',
        creneau: '14:00 - 16:00',
        nbColis: 5,
        poids: 18.0,
        statut: StatutLivraison.enCours,
        notes: 'Entrepôt au fond de la cour',
        dateCreation: now.subtract(const Duration(hours: 3)),
        vehiculeId: 'v2',
      ),
      Livraison(
        id: 'l3',
        clientId: 'c2',
        nomClient: 'Miora Razafindramboa',
        adresse: 'Ampasampito, Antananarivo 102',
        creneau: '10:00 - 12:00',
        nbColis: 2,
        poids: 5.8,
        statut: StatutLivraison.enAttente,
        notes: 'Boutique de vêtements - Livraison côté rue',
        dateCreation: now.subtract(const Duration(days: 1)),
      ),
      Livraison(
        id: 'l4',
        clientId: 'c5',
        nomClient: 'Voahangy Rakotomalala',
        adresse: 'Tsaralalana, Antananarivo 101',
        creneau: '15:00 - 17:00',
        nbColis: 1,
        poids: 3.2,
        statut: StatutLivraison.enAttente,
        dateCreation: now.subtract(const Duration(days: 1)),
      ),
      Livraison(
        id: 'l5',
        clientId: 'c8',
        nomClient: 'Mahery Razafimandimby',
        adresse: 'Andraisoro, Antananarivo 101',
        creneau: '09:00 - 11:00',
        nbColis: 4,
        poids: 9.5,
        statut: StatutLivraison.enAttente,
        dateCreation: now.subtract(const Duration(hours: 5)),
      ),
      Livraison(
        id: 'l6',
        clientId: 'c4',
        nomClient: 'Lanto Rasolofonirina',
        adresse: 'Andranomena, Mahajanga 401',
        creneau: '08:00 - 10:00',
        nbColis: 2,
        poids: 7.0,
        statut: StatutLivraison.livree,
        notes: 'Signature : L. Rasolofonirina',
        dateCreation: now.subtract(const Duration(days: 1, hours: 2)),
        vehiculeId: 'v3',
      ),
      Livraison(
        id: 'l7',
        clientId: 'c6',
        nomClient: 'Nantenaina Randrianasolo',
        adresse: 'Ambohimanarina, Antananarivo 101',
        creneau: '11:00 - 13:00',
        nbColis: 3,
        poids: 11.2,
        statut: StatutLivraison.livree,
        dateCreation: now.subtract(const Duration(days: 2)),
        vehiculeId: 'v1',
      ),
      Livraison(
        id: 'l8',
        clientId: 'c9',
        nomClient: 'Hary Rakotondrabe',
        adresse: 'Ankadindramamy, Antananarivo 101',
        creneau: '16:00 - 18:00',
        nbColis: 6,
        poids: 24.0,
        statut: StatutLivraison.livree,
        dateCreation: now.subtract(const Duration(days: 2, hours: 3)),
        vehiculeId: 'v2',
      ),
      Livraison(
        id: 'l9',
        clientId: 'c7',
        nomClient: 'Fitia Rakotozafy',
        adresse: 'Ambatobe, Antananarivo 102',
        creneau: '13:00 - 15:00',
        nbColis: 1,
        poids: 2.5,
        statut: StatutLivraison.aReporter,
        notes: 'Client absent - À reporter demain',
        dateCreation: now.subtract(const Duration(days: 1)),
      ),
      Livraison(
        id: 'l10',
        clientId: 'c10',
        nomClient: 'Tiavina Randrianarivelo',
        adresse: 'Ankadifotsy, Antananarivo 102',
        creneau: '10:00 - 12:00',
        nbColis: 2,
        poids: 4.8,
        statut: StatutLivraison.annulee,
        notes: 'Annulé par le client - Commande modifiée',
        dateCreation: now.subtract(const Duration(days: 3)),
      ),
      Livraison(
        id: 'l11',
        clientId: 'c1',
        nomClient: 'Rivo Rakoto',
        adresse: 'Andraharo',
        creneau: '09:00 - 11:00',
        nbColis: 2,
        poids: 6.0,
        statut: StatutLivraison.livree,
        dateCreation: now.subtract(const Duration(days: 3, hours: 1)),
        vehiculeId: 'v1',
      ),
      Livraison(
        id: 'l12',
        clientId: 'c2',
        nomClient: 'Miora Razafindramboa',
        adresse: 'Ampasampito, Antananarivo 102',
        creneau: '10:00 - 12:00',
        nbColis: 3,
        poids: 8.5,
        statut: StatutLivraison.livree,
        dateCreation: now.subtract(const Duration(days: 4)),
        vehiculeId: 'v2',
      ),
      Livraison(
        id: 'l13',
        clientId: 'c3',
        nomClient: 'Tahina Andriamanantena',
        adresse: 'Tanjombato, Antananarivo 102',
        creneau: '14:00 - 16:00',
        nbColis: 4,
        poids: 14.0,
        statut: StatutLivraison.livree,
        dateCreation: now.subtract(const Duration(days: 4, hours: 2)),
        vehiculeId: 'v3',
      ),
      Livraison(
        id: 'l14',
        clientId: 'c4',
        nomClient: 'Lanto Rasolofonirina',
        adresse: 'Mahajanga 401',
        creneau: '08:00 - 10:00',
        nbColis: 1,
        poids: 3.0,
        statut: StatutLivraison.enAttente,
        dateCreation: now.subtract(const Duration(days: 5)),
      ),
      Livraison(
        id: 'l15',
        clientId: 'c5',
        nomClient: 'Voahangy Rakotomalala',
        adresse: 'Tsaralalana, Antananarivo 101',
        creneau: '15:00 - 17:00',
        nbColis: 5,
        poids: 16.0,
        statut: StatutLivraison.livree,
        dateCreation: now.subtract(const Duration(days: 5, hours: 3)),
        vehiculeId: 'v1',
      ),
    ];

    for (final livraison in livraisons) {
      await db.insert('livraisons', livraison.toMap());
    }

    final historique = [
      HistoriqueLivraison(
        id: 'h1',
        clientId: 'c1',
        date: _formatDate(now.subtract(const Duration(days: 5))),
        adresse: 'Andraharo',
        statut: StatutHistorique.livree,
        livraisonId: 'l11',
      ),
      HistoriqueLivraison(
        id: 'h2',
        clientId: 'c1',
        date: _formatDate(now.subtract(const Duration(days: 12))),
        adresse: 'Andraharo',
        statut: StatutHistorique.livree,
      ),
      HistoriqueLivraison(
        id: 'h3',
        clientId: 'c2',
        date: _formatDate(now.subtract(const Duration(days: 4))),
        adresse: 'Ampasampito, Antananarivo 102',
        statut: StatutHistorique.livree,
        livraisonId: 'l12',
      ),
      HistoriqueLivraison(
        id: 'h4',
        clientId: 'c2',
        date: _formatDate(now.subtract(const Duration(days: 8))),
        adresse: 'Ampasampito, Antananarivo 102',
        statut: StatutHistorique.reportee,
      ),
      HistoriqueLivraison(
        id: 'h5',
        clientId: 'c3',
        date: _formatDate(now.subtract(const Duration(days: 4))),
        adresse: 'Tanjombato, Antananarivo 102',
        statut: StatutHistorique.livree,
        livraisonId: 'l13',
      ),
      HistoriqueLivraison(
        id: 'h6',
        clientId: 'c4',
        date: _formatDate(now.subtract(const Duration(days: 10))),
        adresse: 'Andranomena, Mahajanga 401',
        statut: StatutHistorique.livree,
      ),
      HistoriqueLivraison(
        id: 'h7',
        clientId: 'c5',
        date: _formatDate(now.subtract(const Duration(days: 5))),
        adresse: 'Tsaralalana, Antananarivo 101',
        statut: StatutHistorique.livree,
        livraisonId: 'l15',
      ),
      HistoriqueLivraison(
        id: 'h8',
        clientId: 'c6',
        date: _formatDate(now.subtract(const Duration(days: 7))),
        adresse: 'Ambohimanarina, Antananarivo 101',
        statut: StatutHistorique.livree,
      ),
      HistoriqueLivraison(
        id: 'h9',
        clientId: 'c6',
        date: _formatDate(now.subtract(const Duration(days: 14))),
        adresse: 'Ambohimanarina, Antananarivo 101',
        statut: StatutHistorique.echouee,
      ),
      HistoriqueLivraison(
        id: 'h10',
        clientId: 'c8',
        date: _formatDate(now.subtract(const Duration(days: 6))),
        adresse: 'Andraisoro, Antananarivo 101',
        statut: StatutHistorique.livree,
      ),
      HistoriqueLivraison(
        id: 'h11',
        clientId: 'c9',
        date: _formatDate(now.subtract(const Duration(days: 9))),
        adresse: 'Ankadindramamy, Antananarivo 101',
        statut: StatutHistorique.livree,
      ),
      HistoriqueLivraison(
        id: 'h12',
        clientId: 'c10',
        date: _formatDate(now.subtract(const Duration(days: 11))),
        adresse: 'Ankadifotsy, Antananarivo 102',
        statut: StatutHistorique.livree,
      ),
    ];

    for (final h in historique) {
      await db.insert('historique', h.toMap());
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} · ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    if (month < 1 || month > 12) return 'invalide';
    return months[month - 1];
  }

  // ========== CRUD Clients ==========
  Future<List<Client>> getAllClients() async {
    final db = await database;
    final result = await db.query('clients', orderBy: 'nom ASC');
    return result.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getClient(String id) async {
    final db = await database;
    final result = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Client.fromMap(result.first);
  }

  Future<void> insertClient(Client client) async {
    final db = await database;
    await db.insert('clients', client.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateClient(Client client) async {
    final db = await database;
    await db.update('clients', client.toMap(), where: 'id = ?', whereArgs: [client.id]);
  }

  Future<void> deleteClient(String id) async {
    final db = await database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD Livraisons ==========
  Future<List<Livraison>> getAllLivraisons() async {
    final db = await database;
    final result = await db.query('livraisons', orderBy: 'date_creation DESC');
    return result.map((map) => Livraison.fromMap(map)).toList();
  }

  Future<List<Livraison>> getLivraisonsByClient(String clientId) async {
    final db = await database;
    final result = await db.query(
      'livraisons',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'date_creation DESC',
    );
    return result.map((map) => Livraison.fromMap(map)).toList();
  }

  Future<List<Livraison>> getLivraisonsByStatut(StatutLivraison statut) async {
    final db = await database;
    final result = await db.query(
      'livraisons',
      where: 'statut = ?',
      whereArgs: [statut.toJson],
      orderBy: 'date_creation DESC',
    );
    return result.map((map) => Livraison.fromMap(map)).toList();
  }

  Future<Livraison?> getLivraison(String id) async {
    final db = await database;
    final result = await db.query('livraisons', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Livraison.fromMap(result.first);
  }

  Future<void> insertLivraison(Livraison livraison) async {
    final db = await database;
    await db.insert('livraisons', livraison.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateLivraison(Livraison livraison) async {
    final db = await database;
    await db.update('livraisons', livraison.toMap(), where: 'id = ?', whereArgs: [livraison.id]);
  }

  Future<void> deleteLivraison(String id) async {
    final db = await database;
    await db.delete('livraisons', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD Véhicules ==========
  Future<List<Vehicule>> getAllVehicules() async {
    final db = await database;
    final result = await db.query('vehicules', orderBy: 'marque ASC');
    return result.map((map) => Vehicule.fromMap(map)).toList();
  }

  Future<Vehicule?> getVehicule(String id) async {
    final db = await database;
    final result = await db.query('vehicules', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Vehicule.fromMap(result.first);
  }

  Future<void> insertVehicule(Vehicule vehicule) async {
    final db = await database;
    await db.insert('vehicules', vehicule.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateVehicule(Vehicule vehicule) async {
    final db = await database;
    await db.update('vehicules', vehicule.toMap(), where: 'id = ?', whereArgs: [vehicule.id]);
  }

  Future<void> deleteVehicule(String id) async {
    final db = await database;
    await db.update('livraisons', {'vehicule_id': null}, where: 'vehicule_id = ?', whereArgs: [id]);
    await db.delete('vehicules', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD Historique ==========
  Future<List<HistoriqueLivraison>> getHistoriqueByClient(String clientId) async {
    final db = await database;
    final result = await db.query(
      'historique',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
    );
    return result.map((map) => HistoriqueLivraison.fromMap(map)).toList();
  }

  // ========== CRUD Entretiens ==========
  Future<List<EntretienItem>> getEntretiensByVehicule(String vehiculeId) async {
    final db = await database;
    final result = await db.query('entretiens', where: 'vehicule_id = ?', whereArgs: [vehiculeId]);
    return result.map((map) => EntretienItem.fromMap(map)).toList();
  }

  Future<void> insertEntretien(EntretienItem entretien) async {
    final db = await database;
    await db.insert('entretiens', entretien.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateEntretien(EntretienItem entretien) async {
    final db = await database;
    await db.update('entretiens', entretien.toMap(), where: 'id = ?', whereArgs: [entretien.id]);
  }

  Future<void> deleteEntretien(String id) async {
    final db = await database;
    await db.delete('entretiens', where: 'id = ?', whereArgs: [id]);
  }
}