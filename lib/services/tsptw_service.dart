// lib/services/tsptw_service.dart
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
  static const double _distancePenaltyWeight = 0.8;
  static const double _earlyArrivalPenalty = 1.5;
  static const double _lateArrivalPenalty = 10.0;
  static const double _maxReasonableDistanceKm = 80.0;

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

  // Phase 1 : Nearest Neighbor avec score combiné distance + créneau
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

        final score = _penalty(stops[j], arrival) + distance * _distancePenaltyWeight;

        if (score < bestScore) {
          bestScore = score;
          best = j;
        }
      }

      if (best == -1) break;

      visited[best] = true;
      tour.add(best);
      final travel = _travelMin(currentPos, stops[best].position);
      currentTime += travel;

      if (currentTime < stops[best].windowStart) {
        currentTime = stops[best].windowStart.toDouble();
      }
      currentTime += stops[best].serviceMinutes;
      currentPos = stops[best].position;
    }

    return tour;
  }

  // Phase 2 : 2-opt local search améliorée
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
          if (j - i <= 1) continue;

          final posPrev = i == 0 ? origin : stops[best[i - 1]].position;
          final posI = stops[best[i]].position;
          final posJ = stops[best[j]].position;
          final posNextJ = j + 1 < best.length ? stops[best[j + 1]].position : null;

          double costBefore = haversine(posPrev, posI);
          costBefore += haversine(posJ, posNextJ ?? posJ);

          double costAfter = haversine(posPrev, posJ);
          costAfter += haversine(posI, posNextJ ?? posI);

          final directJump = haversine(posI, posJ);
          if (directJump > _maxReasonableDistanceKm) continue;

          if (costAfter < costBefore - 0.05) {
            final newTour = List<int>.from(best);
            final reversed = best.sublist(i, j + 1).reversed.toList();
            for (int k = 0; k < reversed.length; k++) {
              newTour[i + k] = reversed[k];
            }

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

  // Évaluation d'un ordre de tournée
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

  // Point d'entrée principal : optimise la tournée
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

    final nnTour = _nearestNeighbor(stops, origin, startMin);
    print('  → Tournée initiale: ${nnTour.length} arrêts');

    final optimizedTour = _twoOpt(nnTour, stops, origin);
    print('  → Tournée optimisée: ${optimizedTour.length} arrêts');

    final result = _evaluate(optimizedTour, stops, origin, startMin);
    print('  → Distance totale: ${result.totalDistanceKm.toStringAsFixed(1)} km');

    return result;
  }

  //Formats supportés :
  static (int, int) parseCreneau(String creneau) {
    try {
      String clean = creneau.trim();

      clean = clean.replaceAll('–', '-');
      clean = clean.replaceAll('—', '-');
      clean = clean.replaceAll('−', '-');


      if (clean.contains('h')) {
        final hIndex = clean.indexOf('h');
        if (hIndex >= 0) {
          String beforeH = clean.substring(0, hIndex);
          String afterH = '';
          if (hIndex + 1 < clean.length) {
            afterH = clean.substring(hIndex + 1);
          }
          String minutes = '';
          for (int i = 0; i < afterH.length; i++) {
            final char = afterH[i];
            if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
              minutes += char;
            } else {
              break;
            }
          }

          String hourStr = beforeH;
          if (hourStr.length == 1) hourStr = '0$hourStr';

          String minuteStr = minutes;
          if (minuteStr.isEmpty) minuteStr = '00';
          if (minuteStr.length == 1) minuteStr = '0$minuteStr';

          // Remplacer "08h00" par "08:00"
          clean = clean.replaceRange(0, clean.length,
              clean.replaceFirst(RegExp(r'\d+h\d*'), '$hourStr:$minuteStr'));
        }
      }

      // Supprimer les espaces autour du séparateur
      clean = clean.replaceAll(' ', '');

      // Split sur le tiret
      final parts = clean.split('-');
      if (parts.length != 2) {
        print('⚠️ parseCreneau: format invalide pour "$creneau", fallback 8h-18h');
        return (8 * 60, 18 * 60);
      }

      int parseTime(String t) {
        // Nettoyer la chaîne
        String timeStr = t.trim();

        // Si c'est un format "HH:MM"
        if (timeStr.contains(':')) {
          final tp = timeStr.split(':');
          int hour = int.parse(tp[0]);
          int minute = tp.length > 1 ? int.parse(tp[1]) : 0;
          return hour * 60 + minute;
        }

        // Si c'est un format "HHMM" (ex: 0800)
        if (timeStr.length == 4) {
          int hour = int.parse(timeStr.substring(0, 2));
          int minute = int.parse(timeStr.substring(2, 4));
          return hour * 60 + minute;
        }

        // Sinon, essayer de parser comme heure simple
        int hour = int.parse(timeStr);
        return hour * 60;
      }

      final start = parseTime(parts[0]);
      final end = parseTime(parts[1]);

      // Validation: l'heure de fin doit être après l'heure de début
      if (end <= start) {
        print('⚠️ parseCreneau: heure de fin ($end) <= heure de début ($start) pour "$creneau", ajustement +1h');
        return (start, start + 60);
      }

      final startHour = start ~/ 60;
      final startMin = (start % 60).toString().padLeft(2, '0');
      final endHour = end ~/ 60;
      final endMin = (end % 60).toString().padLeft(2, '0');

      print('✅ parseCreneau: "$creneau" → ${startHour}h$startMin - ${endHour}h$endMin');

      return (start, end);
    } catch (e) {
      print('❌ parseCreneau error: "$creneau" → $e');
      return (8 * 60, 18 * 60);
    }
  }
}