// lib/viewmodels/carte_viewmodel.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/livraison.dart';
import '../viewmodels/livraisons_viewmodel.dart';
import '../services/tsptw_service.dart';
import '../services/osrm_service.dart';
import '../services/location_service.dart';
// ─── State ───────────────────────────────────────────────────────────────────

enum MapStatus { idle, locating, geocoding, computing, fetchingRoute, ready, error }

class GeocodingProgress {
  final int done;
  final int total;
  final String? currentAddress;
  final List<String> failedAddresses;

  const GeocodingProgress({
    required this.done,
    required this.total,
    this.currentAddress,
    this.failedAddresses = const [],
  });

  double get fraction => total == 0 ? 0 : done / total;
  String get label =>
      currentAddress != null ? 'Géocodage : $currentAddress' : 'Géocodage...';
}

class CarteState {
  final MapStatus status;
  final RouteResult? routeResult;
  final List<LatLng>? osrmGeometry;
  final LatLng? userLocation;
  final LocationSource? locationSource;
  final double? locationAccuracyM;
  final double? osrmDistanceKm;
  final double? osrmDurationMin;
  final bool useOsrm;
  final String? errorMessage;
  final GeocodingProgress? geocodingProgress;
  final List<Livraison> allLivraisons;
  final List<String> failedGeocodingAddresses;

  const CarteState({
    this.status = MapStatus.idle,
    this.routeResult,
    this.osrmGeometry,
    this.userLocation,
    this.locationSource,
    this.locationAccuracyM,
    this.osrmDistanceKm,
    this.osrmDurationMin,
    this.useOsrm = false,
    this.errorMessage,
    this.geocodingProgress,
    this.allLivraisons = const [],
    this.failedGeocodingAddresses = const [],
  });

  bool get isLoading => status != MapStatus.ready &&
      status != MapStatus.idle &&
      status != MapStatus.error;

  bool get hasRealLocation =>
      locationSource == LocationSource.gps ||
          locationSource == LocationSource.network;

  double get displayDistance =>
      useOsrm
          ? (osrmDistanceKm ?? routeResult?.totalDistanceKm ?? 0)
          : (routeResult?.totalDistanceKm ?? 0);

  double get displayDuration =>
      useOsrm
          ? (osrmDurationMin ?? routeResult?.totalDurationMin ?? 0)
          : (routeResult?.totalDurationMin ?? 0);

  CarteState copyWith({
    MapStatus? status,
    RouteResult? routeResult,
    List<LatLng>? osrmGeometry,
    LatLng? userLocation,
    LocationSource? locationSource,
    double? locationAccuracyM,
    double? osrmDistanceKm,
    double? osrmDurationMin,
    bool? useOsrm,
    String? errorMessage,
    GeocodingProgress? geocodingProgress,
    List<Livraison>? allLivraisons,
    List<String>? failedGeocodingAddresses,
  }) {
    return CarteState(
      status: status ?? this.status,
      routeResult: routeResult ?? this.routeResult,
      osrmGeometry: osrmGeometry ?? this.osrmGeometry,
      userLocation: userLocation ?? this.userLocation,
      locationSource: locationSource ?? this.locationSource,
      locationAccuracyM: locationAccuracyM ?? this.locationAccuracyM,
      osrmDistanceKm: osrmDistanceKm ?? this.osrmDistanceKm,
      osrmDurationMin: osrmDurationMin ?? this.osrmDurationMin,
      useOsrm: useOsrm ?? this.useOsrm,
      errorMessage: errorMessage ?? this.errorMessage,
      geocodingProgress: geocodingProgress ?? this.geocodingProgress,
      allLivraisons: allLivraisons ?? this.allLivraisons,
      failedGeocodingAddresses: failedGeocodingAddresses ?? this.failedGeocodingAddresses,
    );
  }
}

// ─── ViewModel ───────────────────────────────────────────────────────────────

class CarteViewModel extends StateNotifier<CarteState> {
  final Ref _ref;
  static const double _maxDistanceFromOriginKm = 50.0;

  // ✅ Subscription pour écouter les changements de livraisons
  late final ProviderSubscription _livraisonsSubscription;

  // Flag pour éviter les optimisations multiples en rafale
  bool _isOptimizing = false;
  Timer? _debounceTimer;

  CarteViewModel(this._ref) : super(const CarteState()) {
    _init();

    // ✅ Écouter les changements dans les livraisons
    _livraisonsSubscription = _ref.listen(
      livraisonsViewModelProvider,
          (previous, next) {
        _onLivraisonsChanged(previous, next);
      },
    );
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> _init() async {
    await GeocodingCache.init();
    await _locateUser();
    await _loadAllLivraisons();
    await optimizeRoute();
  }

  Future<void> _loadAllLivraisons() async {
    final allLivraisons = _ref.read(livraisonsViewModelProvider).livraisons;
    state = state.copyWith(allLivraisons: allLivraisons);
  }

  // ── ✅ NOUVEAU : Réaction aux changements de livraisons ────────────────────

  Future<void> _onLivraisonsChanged(
      LivraisonsState? previous,
      LivraisonsState current,
      ) async {
    if (previous == null) return;

    // Extraire les IDs des livraisons en cours
    final prevEnCoursIds = previous.livraisons
        .where((l) => l.statut == StatutLivraison.enCours)
        .map((l) => l.id)
        .toSet();

    final currEnCoursIds = current.livraisons
        .where((l) => l.statut == StatutLivraison.enCours)
        .map((l) => l.id)
        .toSet();

    // Vérifier si la liste des livraisons en cours a vraiment changé
    final hasChanged = prevEnCoursIds.length != currEnCoursIds.length ||
        !currEnCoursIds.containsAll(prevEnCoursIds);

    if (hasChanged) {
      print('🔄 Optimisation automatique déclenchée');
      print('   Livraisons en cours: ${prevEnCoursIds.length} → ${currEnCoursIds.length}');

      // Mettre à jour la liste des livraisons
      state = state.copyWith(allLivraisons: current.livraisons);

      // Debounce pour éviter les optimisations multiples en rafale
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        await optimizeRoute();
      });
    }
  }

  // ── Géolocalisation GPS réelle ────────────────────────────────────────────

  Future<void> _locateUser() async {
    state = state.copyWith(status: MapStatus.locating);

    final result = await LocationService.getCurrentLocation();

    if (result != null) {
      state = state.copyWith(
        userLocation: result.position,
        locationSource: result.source,
        locationAccuracyM: result.accuracyM,
      );
      print('📍 Localisation: ${result.position.lat}, ${result.position.lng} - Source: ${result.source}');
    } else {
      print('❌ Aucune localisation obtenue');
    }
  }

  // ── Géocodage réel des adresses avec validation ───────────────────────────

  /// Convertit une Livraison en StopTSPTW avec coordonnées réelles (Nominatim)
  /// Retourne null si l'adresse est invalide ou trop éloignée
  Future<StopTSPTW?> _geocodeLivraison(
      Livraison l,
      void Function(String addr) onProgress,
      LatLng? origin,
      List<String> failedAddresses,
      ) async {
    onProgress(l.adresse);

    final pos = await OsrmService.geocode(l.adresse);

    if (pos == null) {
      print('⚠️ Adresse non trouvée: ${l.adresse}');
      failedAddresses.add(l.adresse);
      return null;
    }

    // ✅ Vérifier la cohérence géographique (éviter les bonds aberrants)
    if (origin != null) {
      final distanceToOrigin = TsptwService.haversine(origin, pos);
      if (distanceToOrigin > _maxDistanceFromOriginKm) {
        print('⚠️ Adresse trop éloignée (${distanceToOrigin.toStringAsFixed(0)}km > ${_maxDistanceFromOriginKm}km): ${l.adresse}');
        failedAddresses.add(l.adresse);
        return null;
      }
    }

    final (start, end) = TsptwService.parseCreneau(l.creneau);
    print('✅ Adresse géocodée: ${l.adresse} → (${pos.lat.toStringAsFixed(4)}, ${pos.lng.toStringAsFixed(4)})');

    return StopTSPTW(
      id: l.id,
      nomClient: l.nomClient,
      adresse: l.adresse,
      position: pos,
      windowStart: start,
      windowEnd: end,
      serviceMinutes: 10 + (l.nbColis * 2),
      statut: l.statut,
    );
  }

  // ── Optimisation TSPTW + OSRM ─────────────────────────────────────────────

  Future<void> optimizeRoute() async {
    // Éviter les optimisations multiples simultanées
    if (_isOptimizing) {
      print('⏳ Optimisation déjà en cours, ignorée');
      return;
    }

    _isOptimizing = true;

    try {
      // Filtrer UNIQUEMENT les livraisons "en cours"
      final livraisonsEnCours = _ref
          .read(livraisonsViewModelProvider)
          .livraisons
          .where((l) => l.statut == StatutLivraison.enCours)
          .toList();

      print('📦 Livraisons EN COURS: ${livraisonsEnCours.length}');

      if (livraisonsEnCours.isEmpty) {
        state = state.copyWith(status: MapStatus.idle, routeResult: null);
        return;
      }

      // ── Étape 1 : Géolocalisation ────────────────────────────────────────
      if (state.userLocation == null) {
        await _locateUser();
      }

      if (state.userLocation == null) {
        state = state.copyWith(
          status: MapStatus.error,
          errorMessage: 'Position GPS indisponible. Veuillez activer la localisation.',
        );
        return;
      }

      print('📍 Origine: ${state.userLocation!.lat}, ${state.userLocation!.lng}');

      // ── Étape 2 : Géocodage des adresses ────────────────────────────────
      state = state.copyWith(
        status: MapStatus.geocoding,
        geocodingProgress: GeocodingProgress(done: 0, total: livraisonsEnCours.length),
      );

      int done = 0;
      final stops = <StopTSPTW>[];
      final failedAddresses = <String>[];

      for (final l in livraisonsEnCours) {
        final stop = await _geocodeLivraison(l, (addr) {
          state = state.copyWith(
            geocodingProgress: GeocodingProgress(
              done: done,
              total: livraisonsEnCours.length,
              currentAddress: addr,
              failedAddresses: failedAddresses,
            ),
          );
        }, state.userLocation, failedAddresses);

        done++;
        if (stop != null) stops.add(stop);
      }

      // Mettre à jour l'état avec les adresses en échec
      state = state.copyWith(failedGeocodingAddresses: failedAddresses);

      if (stops.isEmpty) {
        state = state.copyWith(
          status: MapStatus.error,
          errorMessage: 'Aucune adresse n\'a pu être géocodée. ${failedAddresses.length} adresse(s) invalide(s).',
        );
        return;
      }

      // Afficher un avertissement si des adresses ont échoué
      if (failedAddresses.isNotEmpty) {
        print('⚠️ ${failedAddresses.length} adresse(s) non géocodée(s) ou trop éloignée(s)');
      }

      print('📍 Stops géocodés valides: ${stops.length}/${livraisonsEnCours.length}');

      // ── Étape 3 : Algorithme TSPTW ───────────────────────────────────────
      state = state.copyWith(
        status: MapStatus.computing,
        geocodingProgress: null,
      );

      final origin = state.userLocation!;
      final result = TsptwService.optimize(stops: stops, origin: origin);

      print('📊 Tournée calculée: ${result.orderedStops.length} arrêts, ${result.totalDistanceKm.toStringAsFixed(1)} km');

      state = state.copyWith(
        status: MapStatus.fetchingRoute,
        routeResult: result,
      );

      // ── Étape 4 : Route réelle OSRM ──────────────────────────────────────
      final waypoints = [
        origin,
        ...result.orderedStops.map((s) => s.position),
      ];

      final osrm = await OsrmService.getRoute(waypoints);

      if (osrm != null && osrm.geometry.length >= 2) {
        print('✅ Route OSRM récupérée: ${osrm.distanceKm.toStringAsFixed(1)} km, ${osrm.durationMin.toStringAsFixed(0)} min');
        state = state.copyWith(
          status: MapStatus.ready,
          osrmGeometry: osrm.geometry,
          osrmDistanceKm: osrm.distanceKm,
          osrmDurationMin: osrm.durationMin,
          useOsrm: true,
        );
      } else {
        print('⚠️ OSRM indisponible ou route invalide, fallback Haversine');
        // Fallback: créer une ligne droite entre les points
        state = state.copyWith(
          status: MapStatus.ready,
          osrmGeometry: waypoints,
          useOsrm: false,
        );
      }
    } finally {
      _isOptimizing = false;
    }
  }

  // ── Actions publiques ─────────────────────────────────────────────────────

  Future<void> relocateAndRefresh() async {
    print('🔄 Relocalisation manuelle...');
    state = state.copyWith(userLocation: null, locationSource: null);
    await _locateUser();
    await _loadAllLivraisons();
    await optimizeRoute();
  }

  void refreshLivraisons() async {
    await _loadAllLivraisons();
    await optimizeRoute();
  }

  void startTracking() {
    LocationService.startTracking(
      onPosition: (pos) {
        state = state.copyWith(
          userLocation: pos,
          locationSource: LocationSource.gps,
        );
      },
    );
  }

  void stopTracking() => LocationService.stopTracking();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _livraisonsSubscription.close();
    LocationService.stopTracking();
    super.dispose();
  }
}

// ─── Extension helper pour Set ───────────────────────────────────────────────

extension SetExtension<T> on Set<T> {
  bool containsAll(Set<T> other) {
    for (final item in other) {
      if (!contains(item)) return false;
    }
    return true;
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final carteViewModelProvider = StateNotifierProvider<CarteViewModel, CarteState>(
      (ref) => CarteViewModel(ref),
);