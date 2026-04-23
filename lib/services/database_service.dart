// lib/services/database_service.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../models/livraison.dart';
import '../models/vehicule.dart';
import '../models/user.dart';
import '../models/preuve_livraison.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static String? _currentUserId;
  final Uuid _uuid = const Uuid();

  DatabaseService._internal();

  factory DatabaseService() => _instance;

  // Récupérer l'ID de l'utilisateur courant
  Future<String?> getCurrentUserId() async {
    if (_currentUserId != null) return _currentUserId;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson == null) return null;

    try {
      final user = User.fromMap(jsonDecode(userJson));
      _currentUserId = user.id;
      return _currentUserId;
    } catch (e) {
      return null;
    }
  }

  // Définir l'utilisateur courant (appelé après connexion)
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  // Réinitialiser après déconnexion
  void clearCurrentUser() {
    _currentUserId = null;
  }

  // Réinitialiser la base de données (force la réouverture)
  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    print('✅ Base de données réinitialisée');
  }

  // Forcer le changement d'utilisateur
  Future<void> switchUser(String userId) async {
    if (_currentUserId != userId) {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      _currentUserId = userId;
      print('🔄 Changement d\'utilisateur vers: $userId');
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final userId = await getCurrentUserId();
    // Base de données différente par utilisateur
    final dbName = userId != null ? 'routepulse_$userId.db' : 'routepulse_temp.db';
    String path = join(await getDatabasesPath(), dbName);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table des utilisateurs
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        date_creation TEXT NOT NULL,
        phone TEXT
      )
    ''');

    // Table des clients
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        prenom TEXT NOT NULL,
        nom TEXT NOT NULL,
        adresse TEXT NOT NULL,
        phone TEXT,
        rang TEXT NOT NULL,
        est_recurrent INTEGER NOT NULL,
        livraisons_total INTEGER NOT NULL DEFAULT 0,
        taux_succes REAL NOT NULL DEFAULT 0,
        creneau_prefere TEXT NOT NULL,
        date_creation TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Table des livraisons
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

    // Table des véhicules
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

    // Table de l'historique
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

    // Table des entretiens
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

    // Table des preuves de livraison
    await db.execute('''
      CREATE TABLE preuves_livraison (
        id TEXT PRIMARY KEY,
        livraison_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        photo_path TEXT,
        signature TEXT,
        nb_colis_verifies INTEGER NOT NULL,
        commentaire TEXT,
        FOREIGN KEY (livraison_id) REFERENCES livraisons (id) ON DELETE CASCADE
      )
    ''');

    // Création des index
    await db.execute('CREATE INDEX idx_livraisons_client ON livraisons(client_id)');
    await db.execute('CREATE INDEX idx_livraisons_statut ON livraisons(statut)');
    await db.execute('CREATE INDEX idx_livraisons_vehicule ON livraisons(vehicule_id)');
    await db.execute('CREATE INDEX idx_historique_client ON historique(client_id)');
    await db.execute('CREATE INDEX idx_preuves_livraison ON preuves_livraison(livraison_id)');

    print('✅ Base de données créée avec succès');

    // Ajouter des véhicules de démonstration
    await insertDemoVehicules(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE clients ADD COLUMN notes TEXT');
    }
    if (oldVersion < 3) {
      // Migrations supplémentaires si nécessaires
    }
    if (oldVersion < 4) {
      // Ajout de la table preuves_livraison
      await db.execute('''
        CREATE TABLE IF NOT EXISTS preuves_livraison (
          id TEXT PRIMARY KEY,
          livraison_id TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          photo_path TEXT,
          signature TEXT,
          nb_colis_verifies INTEGER NOT NULL,
          commentaire TEXT,
          FOREIGN KEY (livraison_id) REFERENCES livraisons (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_preuves_livraison ON preuves_livraison(livraison_id)');
    }
    if (oldVersion < 5) {
      // Ajout du champ phone dans la table clients
      try {
        await db.execute('ALTER TABLE clients ADD COLUMN phone TEXT');
        print('✅ Colonne phone ajoutée à la table clients');
      } catch (e) {
        print('⚠️ Migration phone: $e');
      }
    }
  }

  Future<void> insertDemoVehicules(Database db) async {
    print('🚗 Insertion des véhicules de démonstration...');

    final now = DateTime.now().toIso8601String();

    final demoVehicules = [
      {
        'id': _uuid.v4(),
        'marque': 'Yamaha',
        'modele': 'NMAX 125',
        'immatriculation': 'AB-123-CD',
        'type': 'Moto',
        'charge_max_kg': 150,
        'volume_m3': 0.5,
        'annee': 2023,
        'disponibilite': 'disponible',
        'livraisons_total': 45,
        'livraisons_mois': 8,
        'km_parcourus': 12500.0,
        'jours_entretien': 45,
        'date_ajout': now,
      },
      {
        'id': _uuid.v4(),
        'marque': 'Renault',
        'modele': 'Clio V',
        'immatriculation': 'CD-456-EF',
        'type': 'Voiture',
        'charge_max_kg': 450,
        'volume_m3': 3.2,
        'annee': 2022,
        'disponibilite': 'indisponible',
        'livraisons_total': 128,
        'livraisons_mois': 22,
        'km_parcourus': 45200.0,
        'jours_entretien': 12,
        'date_ajout': now,
      },
      {
        'id': _uuid.v4(),
        'marque': 'Citroën',
        'modele': 'Jumper',
        'immatriculation': 'EF-789-GH',
        'type': 'Fourgon',
        'charge_max_kg': 1500,
        'volume_m3': 12.5,
        'annee': 2021,
        'disponibilite': 'indisponible',
        'livraisons_total': 89,
        'livraisons_mois': 5,
        'km_parcourus': 78300.0,
        'jours_entretien': 3,
        'date_ajout': now,
      },
      {
        'id': _uuid.v4(),
        'marque': 'Peugeot',
        'modele': 'Partner',
        'immatriculation': 'GH-012-IJ',
        'type': 'Fourgon',
        'charge_max_kg': 800,
        'volume_m3': 4.5,
        'annee': 2023,
        'disponibilite': 'indisponible',
        'livraisons_total': 234,
        'livraisons_mois': 31,
        'km_parcourus': 34200.0,
        'jours_entretien': 60,
        'date_ajout': now,
      },
    ];

    for (final v in demoVehicules) {
      await db.insert('vehicules', v, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    print('✅ ${demoVehicules.length} véhicules de démonstration ajoutés');
  }

  // ========== Gestion des utilisateurs ==========

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<bool> userExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    return result.isNotEmpty;
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

  Future<void> insertHistorique(HistoriqueLivraison historique) async {
    final db = await database;
    await db.insert('historique', historique.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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

  // ========== CRUD Preuves de livraison ==========

  Future<void> insertPreuve(PreuveLivraison preuve) async {
    final db = await database;
    await db.insert('preuves_livraison', preuve.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<PreuveLivraison?> getPreuveByLivraison(String livraisonId) async {
    final db = await database;
    final result = await db.query(
      'preuves_livraison',
      where: 'livraison_id = ?',
      whereArgs: [livraisonId],
    );
    if (result.isEmpty) return null;
    return PreuveLivraison.fromMap(result.first);
  }

  Future<List<PreuveLivraison>> getPreuvesByClient(String clientId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.* FROM preuves_livraison p
      JOIN livraisons l ON p.livraison_id = l.id
      WHERE l.client_id = ?
      ORDER BY p.timestamp DESC
    ''', [clientId]);
    return result.map((map) => PreuveLivraison.fromMap(map)).toList();
  }

  Future<List<PreuveLivraison>> getAllPreuves() async {
    final db = await database;
    final result = await db.query('preuves_livraison', orderBy: 'timestamp DESC');
    return result.map((map) => PreuveLivraison.fromMap(map)).toList();
  }

  Future<void> deletePreuve(String id) async {
    final db = await database;
    await db.delete('preuves_livraison', where: 'id = ?', whereArgs: [id]);
  }

  // ========== Méthodes utilitaires ==========

  // Réinitialiser la base de données de l'utilisateur courant
  Future<void> resetCurrentUserDatabase() async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    final db = await database;
    await db.close();

    String path = join(await getDatabasesPath(), 'routepulse_$userId.db');
    await deleteDatabase(path);
    _database = null;

    print('✅ Base de données réinitialisée pour l\'utilisateur: $userId');
  }

  // Supprimer toutes les données de l'utilisateur courant
  Future<void> deleteAllUserData() async {
    final db = await database;

    // Supprimer toutes les données dans le bon ordre (respect des clés étrangères)
    await db.delete('preuves_livraison');
    await db.delete('entretiens');
    await db.delete('historique');
    await db.delete('livraisons');
    await db.delete('vehicules');
    await db.delete('clients');

    print('✅ Toutes les données utilisateur supprimées');
  }

  // Obtenir les statistiques de l'utilisateur
  Future<Map<String, dynamic>> getUserStats() async {
    final db = await database;

    final clientsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM clients')
    ) ?? 0;

    final livraisonsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM livraisons')
    ) ?? 0;

    final vehiculesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM vehicules')
    ) ?? 0;

    final livraisonsLivrees = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM livraisons WHERE statut = "livree"')
    ) ?? 0;

    final preuvesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM preuves_livraison')
    ) ?? 0;

    return {
      'clients': clientsCount,
      'livraisons': livraisonsCount,
      'vehicules': vehiculesCount,
      'livraisons_livrees': livraisonsLivrees,
      'preuves': preuvesCount,
      'taux_reussite': livraisonsCount > 0 ? livraisonsLivrees / livraisonsCount : 0.0,
    };
  }
}