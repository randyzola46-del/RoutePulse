import 'dart:math';
import '../models/livraison.dart';

// ─── Modèles internes ─────────────────────────────────────────────────────────

class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);
}

class StopTSPTW {
  final String id;
  final String nomClient;
  final String adresse;
  final LatLng position;
  final int windowStart; // minutes depuis minuit
  final int windowEnd;
  final int serviceMinutes;
  final StatutLivraison statut;

  const StopTSPTW({
    required this.id,
    required this.nomClient,
    required this.adresse,
    required this.position,
    required this.windowStart,
    required this.windowEnd,
    required this.serviceMinutes,
    required this.statut,
  });
}

class RouteResult {
  final List<StopTSPTW> orderedStops;
  final List<ArrivalInfo> arrivalInfos;
  final double totalDistanceKm;
  final double totalDurationMin;
  final int windowsRespected;

  const RouteResult({
    required this.orderedStops,
    required this.arrivalInfos,
    required this.totalDistanceKm,
    required this.totalDurationMin,
    required this.windowsRespected,
  });
}

enum WindowStatus { ok, warning, violation }

class ArrivalInfo {
  final double arrivalMin;
  final WindowStatus status;
  final double distFromPrev;

  const ArrivalInfo({
    required this.arrivalMin,
    required this.status,
    required this.distFromPrev,
  });
}

// ─── Service TSPTW ───────────────────────────────────────────────────────────

class TsptwService {
  static const double _avgSpeedKmH = 25.0;
  static const double _distancePenaltyWeight = 0.8; // 🔥 Augmenté de 0.4 à 0.8
  static const double _earlyArrivalPenalty = 1.5;
  static const double _lateArrivalPenalty = 10.0;
  static const double _maxReasonableDistanceKm = 80.0; // Distance max raisonnable

  // Haversine distance en km
  static double haversine(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = (b.lat - a.lat) * pi / 180;
    final dLon = (b.lng - a.lng) * pi / 180;
    final sinDlat = sin(dLat / 2);
    final sinDlon = sin(dLon / 2);
    final x = sinDlat * sinDlat +
        cos(a.lat * pi / 180) * cos(b.lat * pi / 180) * sinDlon * sinDlon;
    return R * 2 * atan2(sqrt(x), sqrt(1 - x));
  }

  static double _travelMin(LatLng from, LatLng to) =>
      (haversine(from, to) / _avgSpeedKmH) * 60;

  /// Vérifie si une distance est raisonnable (évite les bonds aberrants)
  static bool isReasonableDistance(LatLng a, LatLng b, {double maxKm = _maxReasonableDistanceKm}) {
    final dist = haversine(a, b);
    return dist <= maxKm;
  }

  static double _penalty(StopTSPTW stop, double arrivalMin) {
    if (arrivalMin < stop.windowStart) {
      return (stop.windowStart - arrivalMin) * _earlyArrivalPenalty;
    } else if (arrivalMin > stop.windowEnd) {
      return (arrivalMin - stop.windowEnd) * _lateArrivalPenalty;
    }
    return 0.0;
  }

  /// Phase 1 : Nearest Neighbor avec score combiné distance + créneau
  static List<int> _nearestNeighbor(
      List<StopTSPTW> stops,
      LatLng origin,
      double startMin,
      ) {
    if (stops.isEmpty) return [];

    final n = stops.length;
    final visited = List.filled(n, false);
    final tour = <int>[];
    var currentPos = origin;
    var currentTime = startMin;

    for (int step = 0; step < n; step++) {
      int best = -1;
      double bestScore = double.infinity;

      for (int j = 0; j < n; j++) {
        if (visited[j]) continue;

        final travel = _travelMin(currentPos, stops[j].position);
        final arrival = currentTime + travel;
        final distance = haversine(currentPos, stops[j].position);

        // Score = pénalité temporelle + distance × poids renforcé
        final score = _penalty(stops[j], arrival) + distance * _distancePenaltyWeight;

        if (score < bestScore) {
          bestScore = score;
          best = j;
        }
      }

      if (best == -1) break; // Sécurité

      visited[best] = true;
      tour.add(best);
      final travel = _travelMin(currentPos, stops[best].position);
      currentTime += travel;

      // Attente si on arrive avant l'ouverture du créneau
      if (currentTime < stops[best].windowStart) {
        currentTime = stops[best].windowStart.toDouble();
      }
      currentTime += stops[best].serviceMinutes;
      currentPos = stops[best].position;
    }

    return tour;
  }

  /// Phase 2 : 2-opt local search améliorée
  static List<int> _twoOpt(List<int> tour, List<StopTSPTW> stops, LatLng origin) {
    if (tour.length < 3) return tour;

    var best = List<int>.from(tour);
    bool improved = true;
    int iterations = 0;
    const maxIterations = 200;

    while (improved && iterations < maxIterations) {
      improved = false;
      iterations++;

      for (int i = 0; i < best.length - 2; i++) {
        for (int j = i + 2; j < best.length; j++) {
          // Éviter les inversions qui créent des bonds géographiques
          if (j - i <= 1) continue;

          final posPrev = i == 0 ? origin : stops[best[i - 1]].position;
          final posI = stops[best[i]].position;
          final posJ = stops[best[j]].position;
          final posNextJ = j + 1 < best.length ? stops[best[j + 1]].position : null;

          // Distance avant inversion
          double costBefore = haversine(posPrev, posI);
          costBefore += haversine(posJ, posNextJ ?? posJ);

          // Distance après inversion (i ↔ j)
          double costAfter = haversine(posPrev, posJ);
          costAfter += haversine(posI, posNextJ ?? posI);

          // Vérifier que l'inversion ne crée pas un bond aberrant
          final directJump = haversine(posI, posJ);
          if (directJump > _maxReasonableDistanceKm) continue;

          if (costAfter < costBefore - 0.05) {
            // Inverser le segment [i, j]
            final newTour = List<int>.from(best);
            final reversed = best.sublist(i, j + 1).reversed.toList();
            for (int k = 0; k < reversed.length; k++) {
              newTour[i + k] = reversed[k];
            }

            // Vérifier la validité temporelle
            final evalNew = _evaluate(newTour, stops, origin, 8 * 60);
            final evalOld = _evaluate(best, stops, origin, 8 * 60);

            if (evalNew.windowsRespected >= evalOld.windowsRespected &&
                evalNew.totalDistanceKm < evalOld.totalDistanceKm * 0.99) {
              best = newTour;
              improved = true;
              break;
            }
          }
        }
        if (improved) break;
      }
    }

    return best;
  }

  /// Évaluation d'un ordre de tournée
  static RouteResult _evaluate(
      List<int> order,
      List<StopTSPTW> stops,
      LatLng origin,
      double startMin,
      ) {
    var currentTime = startMin;
    var currentPos = origin;
    var totalDist = 0.0;
    var windowsOk = 0;
    final infos = <ArrivalInfo>[];

    for (final idx in order) {
      final stop = stops[idx];
      final d = haversine(currentPos, stop.position);
      totalDist += d;
      final travel = (d / _avgSpeedKmH) * 60;
      currentTime += travel;

      WindowStatus status;
      if (currentTime > stop.windowEnd) {
        status = WindowStatus.violation;
      } else if (currentTime > stop.windowEnd - 20) {
        status = WindowStatus.warning;
      } else {
        status = WindowStatus.ok;
        windowsOk++;
      }

      infos.add(ArrivalInfo(
        arrivalMin: currentTime,
        status: status,
        distFromPrev: d,
      ));

      if (currentTime < stop.windowStart) {
        currentTime = stop.windowStart.toDouble();
      }
      currentTime += stop.serviceMinutes;
      currentPos = stop.position;
    }

    return RouteResult(
      orderedStops: order.map((i) => stops[i]).toList(),
      arrivalInfos: infos,
      totalDistanceKm: totalDist,
      totalDurationMin: currentTime - startMin,
      windowsRespected: windowsOk,
    );
  }

  /// Point d'entrée principal : optimise la tournée
  static RouteResult optimize({
    required List<StopTSPTW> stops,
    required LatLng origin,
    double startMin = 480, // 08h00
  }) {
    if (stops.isEmpty) {
      return RouteResult(
        orderedStops: [],
        arrivalInfos: [],
        totalDistanceKm: 0,
        totalDurationMin: 0,
        windowsRespected: 0,
      );
    }

    print('📍 Optimisation TSPTW avec ${stops.length} arrêts');

    // Phase 1: Nearest Neighbor
    final nnTour = _nearestNeighbor(stops, origin, startMin);
    print('  → Tournée initiale: ${nnTour.length} arrêts');

    // Phase 2: 2-opt
    final optimizedTour = _twoOpt(nnTour, stops, origin);
    print('  → Tournée optimisée: ${optimizedTour.length} arrêts');

    final result = _evaluate(optimizedTour, stops, origin, startMin);
    print('  → Distance totale: ${result.totalDistanceKm.toStringAsFixed(1)} km');

    return result;
  }

  /// Parse un créneau string "08h–10h" ou "08:00–10:00" → [startMin, endMin]
  static (int, int) parseCreneau(String creneau) {
    try {
      final clean = creneau.replaceAll('h', ':00').replaceAll(' ', '');
      final parts = clean.split('–');
      if (parts.length != 2) return (8 * 60, 18 * 60);

      int parseTime(String t) {
        final tp = t.split(':');
        return int.parse(tp[0]) * 60 + (tp.length > 1 ? int.parse(tp[1]) : 0);
      }
      return (parseTime(parts[0]), parseTime(parts[1]));
    } catch (_) {
      return (8 * 60, 18 * 60);
    }
  }
}