// lib/services/encrypted_database_service.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'encryption_service.dart';
import '../models/user.dart';
import '../models/client.dart';
import '../models/livraison.dart';
import '../models/vehicule.dart';
import '../models/preuve_livraison.dart';

/// Version chiffrée du DatabaseService
/// Toutes les données sensibles sont chiffrées avant insertion
class EncryptedDatabaseService {
  static final EncryptedDatabaseService _instance = EncryptedDatabaseService._internal();
  factory EncryptedDatabaseService() => _instance;
  EncryptedDatabaseService._internal();

  static Database? _database;
  static String? _currentUserId;
  final EncryptionService _encryption = EncryptionService();
  final Uuid _uuid = const Uuid();

  // Champs sensibles par table
  static const _clientSensitiveFields = ['prenom', 'nom', 'adresse', 'phone', 'notes'];
  static const _livraisonSensitiveFields = ['nom_client', 'adresse', 'notes'];
  static const _vehiculeSensitiveFields = ['immatriculation'];
  static const _preuveSensitiveFields = ['commentaire'];

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

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  void clearCurrentUser() {
    _currentUserId = null;
  }

  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await _encryption.init();
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final userId = await getCurrentUserId();
    final dbName = userId != null ? 'routepulse_encrypted_$userId.db' : 'routepulse_encrypted_temp.db';
    String path = join(await getDatabasesPath(), dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
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

    // Table des preuves
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

    // Index
    await db.execute('CREATE INDEX idx_livraisons_client ON livraisons(client_id)');
    await db.execute('CREATE INDEX idx_livraisons_statut ON livraisons(statut)');
    await db.execute('CREATE INDEX idx_historique_client ON historique(client_id)');

    print('✅ Base de données chiffrée créée');

    // Insérer véhicules démo
    await _insertDemoVehicules(db);
  }

  Future<void> _insertDemoVehicules(Database db) async {
    final now = DateTime.now().toIso8601String();

    final demoVehicules = [
      {'id': _uuid.v4(), 'marque': 'Yamaha', 'modele': 'NMAX 125', 'immatriculation': _encryption.encryptString('AB-123-CD'), 'type': 'Moto', 'charge_max_kg': 150, 'volume_m3': 0.5, 'annee': 2023, 'disponibilite': 'disponible', 'livraisons_total': 45, 'livraisons_mois': 8, 'km_parcourus': 12500.0, 'jours_entretien': 45, 'date_ajout': now},
      {'id': _uuid.v4(), 'marque': 'Renault', 'modele': 'Clio V', 'immatriculation': _encryption.encryptString('CD-456-EF'), 'type': 'Voiture', 'charge_max_kg': 450, 'volume_m3': 3.2, 'annee': 2022, 'disponibilite': 'indisponible', 'livraisons_total': 128, 'livraisons_mois': 22, 'km_parcourus': 45200.0, 'jours_entretien': 12, 'date_ajout': now},
      {'id': _uuid.v4(), 'marque': 'Citroën', 'modele': 'Jumper', 'immatriculation': _encryption.encryptString('EF-789-GH'), 'type': 'Fourgon', 'charge_max_kg': 1500, 'volume_m3': 12.5, 'annee': 2021, 'disponibilite': 'indisponible', 'livraisons_total': 89, 'livraisons_mois': 5, 'km_parcourus': 78300.0, 'jours_entretien': 3, 'date_ajout': now},
      {'id': _uuid.v4(), 'marque': 'Peugeot', 'modele': 'Partner', 'immatriculation': _encryption.encryptString('GH-012-IJ'), 'type': 'Fourgon', 'charge_max_kg': 800, 'volume_m3': 4.5, 'annee': 2023, 'disponibilite': 'indisponible', 'livraisons_total': 234, 'livraisons_mois': 31, 'km_parcourus': 34200.0, 'jours_entretien': 60, 'date_ajout': now},
    ];

    for (final v in demoVehicules) {
      await db.insert('vehicules', v, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // ========== Gestion utilisateurs ==========

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ========== CRUD Clients ==========

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final result = await db.query('clients', orderBy: 'nom ASC');
    return result.map((map) {
      final decrypted = _encryption.decryptMap(map, _clientSensitiveFields);
      return Client.fromMap(decrypted);
    }).toList();
  }

  Future<Client?> getClient(String id) async {
    final db = await database;
    final result = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    final decrypted = _encryption.decryptMap(result.first, _clientSensitiveFields);
    return Client.fromMap(decrypted);
  }

  Future<void> insertClient(Client client) async {
    final db = await database;
    final encryptedMap = _encryption.encryptMap(client.toMap(), _clientSensitiveFields);
    await db.insert('clients', encryptedMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateClient(Client client) async {
    final db = await database;
    final encryptedMap = _encryption.encryptMap(client.toMap(), _clientSensitiveFields);
    await db.update('clients', encryptedMap, where: 'id = ?', whereArgs: [client.id]);
  }

  Future<void> deleteClient(String id) async {
    final db = await database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD Livraisons ==========

  Future<List<Livraison>> getAllLivraisons() async {
    final db = await database;
    final result = await db.query('livraisons', orderBy: 'date_creation DESC');
    return result.map((map) {
      final decrypted = _encryption.decryptMap(map, _livraisonSensitiveFields);
      return Livraison.fromMap(decrypted);
    }).toList();
  }

  Future<List<Livraison>> getLivraisonsByClient(String clientId) async {
    final db = await database;
    final result = await db.query(
      'livraisons',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'date_creation DESC',
    );
    return result.map((map) {
      final decrypted = _encryption.decryptMap(map, _livraisonSensitiveFields);
      return Livraison.fromMap(decrypted);
    }).toList();
  }

  Future<List<Livraison>> getLivraisonsByStatut(StatutLivraison statut) async {
    final db = await database;
    final result = await db.query(
      'livraisons',
      where: 'statut = ?',
      whereArgs: [statut.toJson],
      orderBy: 'date_creation DESC',
    );
    return result.map((map) {
      final decrypted = _encryption.decryptMap(map, _livraisonSensitiveFields);
      return Livraison.fromMap(decrypted);
    }).toList();
  }

  Future<Livraison?> getLivraison(String id) async {
    final db = await database;
    final result = await db.query('livraisons', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    final decrypted = _encryption.decryptMap(result.first, _livraisonSensitiveFields);
    return Livraison.fromMap(decrypted);
  }

  Future<void> insertLivraison(Livraison livraison) async {
    final db = await database;
    final encryptedMap = _encryption.encryptMap(livraison.toMap(), _livraisonSensitiveFields);
    await db.insert('livraisons', encryptedMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateLivraison(Livraison livraison) async {
    final db = await database;
    final encryptedMap = _encryption.encryptMap(livraison.toMap(), _livraisonSensitiveFields);
    await db.update('livraisons', encryptedMap, where: 'id = ?', whereArgs: [livraison.id]);
  }

  Future<void> deleteLivraison(String id) async {
    final db = await database;
    await db.delete('livraisons', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD Véhicules ==========

  Future<List<Vehicule>> getAllVehicules() async {
    final db = await database;
    final result = await db.query('vehicules', orderBy: 'marque ASC');
    return result.map((map) {
      final decrypted = _encryption.decryptMap(map, _vehiculeSensitiveFields);
      return Vehicule.fromMap(decrypted);
    }).toList();
  }

  Future<Vehicule?> getVehicule(String id) async {
    final db = await database;
    final result = await db.query('vehicules', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    final decrypted = _encryption.decryptMap(result.first, _vehiculeSensitiveFields);
    return Vehicule.fromMap(decrypted);
  }

  Future<void> insertVehicule(Vehicule vehicule) async {
    final db = await database;
    final encryptedMap = _encryption.encryptMap(vehicule.toMap(), _vehiculeSensitiveFields);
    await db.insert('vehicules', encryptedMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateVehicule(Vehicule vehicule) async {
    final db = await database;
    final encryptedMap = _encryption.encryptMap(vehicule.toMap(), _vehiculeSensitiveFields);
    await db.update('vehicules', encryptedMap, where: 'id = ?', whereArgs: [vehicule.id]);
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
    return result.map((map) {
      final decrypted = _encryption.decryptMap(map, ['adresse']);
      return HistoriqueLivraison.fromMap(decrypted);
    }).toList();
  }

  Future<void> insertHistorique(HistoriqueLivraison historique) async {
    final db = await database;
    final encryptedMap = _encryption.encryptMap(historique.toMap(), ['adresse']);
    await db.insert('historique', encryptedMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ========== CRUD Entretiens ==========

  Future<List<EntretienItem>> getEntretiensByVehicule(String vehiculeId) async {
    final db = await database;
    final result = await db.query('entretiens', where: 'vehicule_id = ?', whereArgs: [vehiculeId]);
    return result.map((map) => EntretienItem.fromMap(map)).toList();
  }

  // ========== CRUD Preuves ==========

  Future<void> insertPreuve(PreuveLivraison preuve) async {
    final db = await database;
    final encryptedMap = _encryption.encryptMap(preuve.toMap(), _preuveSensitiveFields);
    await db.insert('preuves_livraison', encryptedMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<PreuveLivraison?> getPreuveByLivraison(String livraisonId) async {
    final db = await database;
    final result = await db.query(
      'preuves_livraison',
      where: 'livraison_id = ?',
      whereArgs: [livraisonId],
    );
    if (result.isEmpty) return null;
    final decrypted = _encryption.decryptMap(result.first, _preuveSensitiveFields);
    return PreuveLivraison.fromMap(decrypted);
  }

  // ========== Statistiques ==========

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

    return {
      'clients': clientsCount,
      'livraisons': livraisonsCount,
      'vehicules': vehiculesCount,
      'livraisons_livrees': livraisonsLivrees,
      'taux_reussite': livraisonsCount > 0 ? livraisonsLivrees / livraisonsCount : 0.0,
    };
  }

  // ========== Utilitaires ==========

  Future<void> deleteAllUserData() async {
    final db = await database;
    await db.delete('preuves_livraison');
    await db.delete('entretiens');
    await db.delete('historique');
    await db.delete('livraisons');
    await db.delete('vehicules');
    await db.delete('clients');
  }
}