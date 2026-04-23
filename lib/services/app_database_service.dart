// lib/services/app_database_service.dart
import '../models/client.dart';
import '../models/livraison.dart';
import '../models/vehicule.dart';
import '../models/user.dart';
import '../models/preuve_livraison.dart';
import 'database_service.dart';
import 'encrypted_database_service.dart';
import 'encryption_service.dart';

/// Service de base de données unifié
/// Utilise le chiffrement si disponible, sinon fallback vers non chiffré
class AppDatabaseService {
  static final AppDatabaseService _instance = AppDatabaseService._internal();
  factory AppDatabaseService() => _instance;
  AppDatabaseService._internal();

  late final DatabaseService _plainDb;
  late final EncryptedDatabaseService _encryptedDb;
  bool _useEncryption = true;
  bool _isInitialized = false;

  Future<void> init({bool useEncryption = true}) async {
    if (_isInitialized) return;

    _useEncryption = useEncryption;

    if (useEncryption) {
      try {
        await EncryptionService().init();
        _encryptedDb = EncryptedDatabaseService();
        print('✅ Base de données chiffrée initialisée');
      } catch (e) {
        print('⚠️ Échec chiffrement, fallback vers base non chiffrée: $e');
        _useEncryption = false;
        _plainDb = DatabaseService();
      }
    } else {
      _plainDb = DatabaseService();
    }

    _isInitialized = true;
  }

  bool get useEncryption => _useEncryption;

  // Délégation vers le service approprié
  Future<String?> getCurrentUserId() async {
    if (_useEncryption) {
      return await _encryptedDb.getCurrentUserId();
    }
    return await _plainDb.getCurrentUserId();
  }

  void setCurrentUserId(String userId) {
    if (_useEncryption) {
      _encryptedDb.setCurrentUserId(userId);
    } else {
      _plainDb.setCurrentUserId(userId);
    }
  }

  void clearCurrentUser() {
    if (_useEncryption) {
      _encryptedDb.clearCurrentUser();
    } else {
      _plainDb.clearCurrentUser();
    }
  }

  Future<void> resetDatabase() async {
    if (_useEncryption) {
      await _encryptedDb.resetDatabase();
    } else {
      await _plainDb.resetDatabase();
    }
  }

  // Clients
  Future<List<Client>> getAllClients() async {
    if (_useEncryption) {
      return await _encryptedDb.getAllClients();
    }
    return await _plainDb.getAllClients();
  }

  Future<Client?> getClient(String id) async {
    if (_useEncryption) {
      return await _encryptedDb.getClient(id);
    }
    return await _plainDb.getClient(id);
  }

  Future<void> insertClient(Client client) async {
    if (_useEncryption) {
      await _encryptedDb.insertClient(client);
    } else {
      await _plainDb.insertClient(client);
    }
  }

  Future<void> updateClient(Client client) async {
    if (_useEncryption) {
      await _encryptedDb.updateClient(client);
    } else {
      await _plainDb.updateClient(client);
    }
  }

  Future<void> deleteClient(String id) async {
    if (_useEncryption) {
      await _encryptedDb.deleteClient(id);
    } else {
      await _plainDb.deleteClient(id);
    }
  }

  // Livraisons
  Future<List<Livraison>> getAllLivraisons() async {
    if (_useEncryption) {
      return await _encryptedDb.getAllLivraisons();
    }
    return await _plainDb.getAllLivraisons();
  }

  Future<List<Livraison>> getLivraisonsByClient(String clientId) async {
    if (_useEncryption) {
      return await _encryptedDb.getLivraisonsByClient(clientId);
    }
    return await _plainDb.getLivraisonsByClient(clientId);
  }

  Future<List<Livraison>> getLivraisonsByStatut(StatutLivraison statut) async {
    if (_useEncryption) {
      return await _encryptedDb.getLivraisonsByStatut(statut);
    }
    return await _plainDb.getLivraisonsByStatut(statut);
  }

  Future<Livraison?> getLivraison(String id) async {
    if (_useEncryption) {
      return await _encryptedDb.getLivraison(id);
    }
    return await _plainDb.getLivraison(id);
  }

  Future<void> insertLivraison(Livraison livraison) async {
    if (_useEncryption) {
      await _encryptedDb.insertLivraison(livraison);
    } else {
      await _plainDb.insertLivraison(livraison);
    }
  }

  Future<void> updateLivraison(Livraison livraison) async {
    if (_useEncryption) {
      await _encryptedDb.updateLivraison(livraison);
    } else {
      await _plainDb.updateLivraison(livraison);
    }
  }

  Future<void> deleteLivraison(String id) async {
    if (_useEncryption) {
      await _encryptedDb.deleteLivraison(id);
    } else {
      await _plainDb.deleteLivraison(id);
    }
  }

  // Véhicules
  Future<List<Vehicule>> getAllVehicules() async {
    if (_useEncryption) {
      return await _encryptedDb.getAllVehicules();
    }
    return await _plainDb.getAllVehicules();
  }

  Future<Vehicule?> getVehicule(String id) async {
    if (_useEncryption) {
      return await _encryptedDb.getVehicule(id);
    }
    return await _plainDb.getVehicule(id);
  }

  Future<void> insertVehicule(Vehicule vehicule) async {
    if (_useEncryption) {
      await _encryptedDb.insertVehicule(vehicule);
    } else {
      await _plainDb.insertVehicule(vehicule);
    }
  }

  Future<void> updateVehicule(Vehicule vehicule) async {
    if (_useEncryption) {
      await _encryptedDb.updateVehicule(vehicule);
    } else {
      await _plainDb.updateVehicule(vehicule);
    }
  }

  Future<void> deleteVehicule(String id) async {
    if (_useEncryption) {
      await _encryptedDb.deleteVehicule(id);
    } else {
      await _plainDb.deleteVehicule(id);
    }
  }

  // Historique
  Future<List<HistoriqueLivraison>> getHistoriqueByClient(String clientId) async {
    if (_useEncryption) {
      return await _encryptedDb.getHistoriqueByClient(clientId);
    }
    return await _plainDb.getHistoriqueByClient(clientId);
  }

  Future<void> insertHistorique(HistoriqueLivraison historique) async {
    if (_useEncryption) {
      await _encryptedDb.insertHistorique(historique);
    } else {
      await _plainDb.insertHistorique(historique);
    }
  }

  // Entretiens
  Future<List<EntretienItem>> getEntretiensByVehicule(String vehiculeId) async {
    if (_useEncryption) {
      return await _encryptedDb.getEntretiensByVehicule(vehiculeId);
    }
    return await _plainDb.getEntretiensByVehicule(vehiculeId);
  }

  // Preuves
  Future<void> insertPreuve(PreuveLivraison preuve) async {
    if (_useEncryption) {
      await _encryptedDb.insertPreuve(preuve);
    } else {
      await _plainDb.insertPreuve(preuve);
    }
  }

  Future<PreuveLivraison?> getPreuveByLivraison(String livraisonId) async {
    if (_useEncryption) {
      return await _encryptedDb.getPreuveByLivraison(livraisonId);
    }
    return await _plainDb.getPreuveByLivraison(livraisonId);
  }

  // Statistiques
  Future<Map<String, dynamic>> getUserStats() async {
    if (_useEncryption) {
      return await _encryptedDb.getUserStats();
    }
    return await _plainDb.getUserStats();
  }

  // Utilitaires
  Future<void> deleteAllUserData() async {
    if (_useEncryption) {
      await _encryptedDb.deleteAllUserData();
    } else {
      await _plainDb.deleteAllUserData();
    }
  }
}