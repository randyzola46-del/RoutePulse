// lib/services/location_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../services/tsptw_service.dart';

// ─── Résultat de la localisation ─────────────────────────────────────────────

enum LocationSource { gps, network, denied, unavailable, fallback }

class LocationResult {
  final LatLng position;
  final LocationSource source;
  final double? accuracyM;

  const LocationResult({
    required this.position,
    required this.source,
    this.accuracyM,
  });

  bool get isReal =>
      source == LocationSource.gps || source == LocationSource.network;
}

// ─── Service de localisation ─────────────────────────────────────────────────

class LocationService {
  // Dernière position connue (mise à jour en continu si stream actif)
  static LatLng? _lastKnown;
  static StreamSubscription<Position>? _sub;

  // Position par défaut pour le développement (Antananarivo)
  static const LatLng _defaultPosition = LatLng(-18.9126, 47.5079);

  static LatLng? get lastKnown => _lastKnown;

  // Demande la permission et retourne la position réelle du téléphone.
  // Retourne une position par défaut en cas d'échec (fallback pour développement).
  static Future<LocationResult> getCurrentLocation() async {
    // 1. Vérifier si le service de localisation est activé
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ Service GPS désactivé → utilisation fallback');
      return LocationResult(
        position: _lastKnown ?? _defaultPosition,
        source: LocationSource.unavailable,
      );
    }

    // 2. Vérifier / demander la permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      print('⚠️ Permission GPS refusée → utilisation fallback');
      return LocationResult(
        position: _lastKnown ?? _defaultPosition,
        source: LocationSource.denied,
      );
    }

    // 3. Obtenir la position GPS réelle
    try {
      // Essai rapide : dernière position connue (< 2 min)
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final age = DateTime.now().difference(last.timestamp);
        if (age.inMinutes < 2) {
          final pos = LatLng(last.latitude, last.longitude);
          _lastKnown = pos;
          print('✅ Position GPS récupérée (cache) : ${pos.lat}, ${pos.lng}');
          return LocationResult(
            position: pos,
            source: LocationSource.network,
            accuracyM: last.accuracy,
          );
        }
      }

      // Position fraîche
      print('📍 Tentative de localisation GPS...');
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final result = LatLng(pos.latitude, pos.longitude);
      _lastKnown = result;
      print('✅ Position GPS récupérée : ${result.lat}, ${result.lng}');

      return LocationResult(
        position: result,
        source: LocationSource.gps,
        accuracyM: pos.accuracy,
      );
    } on TimeoutException {
      print('⏱️ Timeout GPS (trop lent) → tentative réseau...');
      // GPS trop lent → position réseau si dispo
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 4),
          ),
        );
        final result = LatLng(pos.latitude, pos.longitude);
        _lastKnown = result;
        print('✅ Position réseau récupérée : ${result.lat}, ${result.lng}');
        return LocationResult(
          position: result,
          source: LocationSource.network,
          accuracyM: pos.accuracy,
        );
      } catch (e) {
        print('❌ Échec position réseau → fallback');
        return LocationResult(
          position: _lastKnown ?? _defaultPosition,
          source: LocationSource.fallback,
        );
      }
    } catch (e) {
      print('❌ Erreur GPS inattendue : $e → fallback');
      return LocationResult(
        position: _lastKnown ?? _defaultPosition,
        source: LocationSource.fallback,
      );
    }
  }

  // Démarre un stream de position en continu (pour le suivi en livraison).
  static void startTracking({
    required void Function(LatLng) onPosition,
    int distanceFilterM = 20,
  }) {
    _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterM,
      ),
    ).listen((pos) {
      final p = LatLng(pos.latitude, pos.longitude);
      _lastKnown = p;
      onPosition(p);
    });
  }

  // Arrête le tracking.
  static void stopTracking() {
    _sub?.cancel();
    _sub = null;
  }

  // Vérifie si la permission est accordée (sans la demander).
  static Future<bool> hasPermission() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  // Force l'utilisation de la position par défaut (pour tester sans GPS)
  static void setDefaultPosition() {
    _lastKnown = _defaultPosition;
    print('📍 Position forcée à Antananarivo : ${_defaultPosition.lat}, ${_defaultPosition.lng}');
  }
}