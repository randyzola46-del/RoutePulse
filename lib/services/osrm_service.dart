import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'tsptw_service.dart';

// ─── Cache Hive ───────────────────────────────────────────────────────────────
// Les coordonnées géocodées sont persistées localement pour éviter de
// rappeler Nominatim à chaque ouverture (limite Nominatim : 1 req/s).

class GeocodingCache {
  static const _boxName = 'geocoding_cache';
  static Box<String>? _box;

  static Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  static LatLng? get(String address) {
    final raw = _box?.get(_key(address));
    if (raw == null) return null;
    try {
      final parts = raw.split(',');
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  static Future<void> set(String address, LatLng pos) async {
    await _box?.put(_key(address), '${pos.lat},${pos.lng}');
  }

  // Invalider une entrée (ex: adresse corrigée)
  static Future<void> remove(String address) async {
    await _box?.delete(_key(address));
  }

  static String _key(String a) =>
      a.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

// ─── Modèles OSRM ────────────────────────────────────────────────────────────

class OsrmRoute {
  final List<LatLng> geometry;
  final double distanceM;
  final double durationS;

  const OsrmRoute({
    required this.geometry,
    required this.distanceM,
    required this.durationS,
  });

  double get distanceKm => distanceM / 1000;
  double get durationMin => durationS / 60;
}

// ─── Service principal ───────────────────────────────────────────────────────

class OsrmService {
  static const _osrmBase =
      'https://router.project-osrm.org/route/v1/driving/';
  static const _nominatimBase =
      'https://nominatim.openstreetmap.org/search';

  // Nominatim exige max 1 req/s — file sérialisée avec délai 1.1s
  static final _queue = _RequestQueue(delayMs: 1100);

  // ── Routing OSRM ────────────────────────────────────────────────────────

  /// Calcule l'itinéraire routier réel entre waypoints.
  /// Retourne null si OSRM est injoignable (fallback haversine dans le VM).
  static Future<OsrmRoute?> getRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;
    try {
      final coordStr =
          waypoints.map((p) => '${p.lng},${p.lat}').join(';');
      final uri = Uri.parse(
          '$_osrmBase$coordStr?overview=full&geometries=geojson');

      final resp = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final route =
          (data['routes'] as List).first as Map<String, dynamic>;
      final pts =
          (route['geometry']['coordinates'] as List).map((c) {
        final pt = c as List;
        return LatLng(
          (pt[1] as num).toDouble(),
          (pt[0] as num).toDouble(),
        );
      }).toList();

      return OsrmRoute(
        geometry: pts,
        distanceM: (route['distance'] as num).toDouble(),
        durationS: (route['duration'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Géocodage Nominatim (OSM) avec cache Hive ───────────────────────────

  /// Géocode une adresse réelle.
  /// Ordre de résolution :
  ///   1. Cache Hive local  (instantané, hors-ligne)
  ///   2. Nominatim OSM     (réseau, throttlé 1 req/s)
  ///   3. null              (adresse introuvable)
  static Future<LatLng?> geocode(String address) async {
    // 1. Cache
    final cached = GeocodingCache.get(address);
    if (cached != null) return cached;

    // 2. Réseau (sérialisé)
    return _queue.run<LatLng>(() => _nominatim(address));
  }

  static Future<LatLng?> _nominatim(String address) async {
    try {
      final uri = Uri.parse(_nominatimBase).replace(
        queryParameters: {
          'q': address,
          'format': 'json',
          'limit': '1',
          'addressdetails': '0',
        },
      );

      final resp = await http.get(uri, headers: {
        'User-Agent': 'RoutePulse/1.0',
        'Accept-Language': 'fr',
      }).timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) return null;

      final results = jsonDecode(resp.body) as List;
      if (results.isEmpty) return null;

      final r = results.first as Map<String, dynamic>;
      final pos = LatLng(
        double.parse(r['lat'] as String),
        double.parse(r['lon'] as String),
      );

      await GeocodingCache.set(address, pos);
      return pos;
    } catch (_) {
      return null;
    }
  }

  /// Géocode une liste d'adresses séquentiellement (throttle respecté).
  static Future<Map<String, LatLng?>> geocodeBatch(
      List<String> addresses) async {
    final out = <String, LatLng?>{};
    for (final addr in addresses) {
      out[addr] = await geocode(addr);
    }
    return out;
  }
}

// ─── File d'attente avec throttle ───────────────────────────────────────────

class _RequestQueue {
  final int delayMs;
  final _pending = <_Task>[];
  bool _busy = false;

  _RequestQueue({required this.delayMs});

  Future<T?> run<T>(Future<T?> Function() fn) {
    final c = Completer<T?>();
    _pending.add(_Task(fn, c));
    if (!_busy) _drain();
    return c.future;
  }

  Future<void> _drain() async {
    _busy = true;
    while (_pending.isNotEmpty) {
      final t = _pending.removeAt(0);
      try {
        final res = await t.fn();
        t.completer.complete(res);
      } catch (e, s) {
        t.completer.completeError(e, s);
      }
      if (_pending.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    _busy = false;
  }
}

class _Task {
  final Future<dynamic> Function() fn;
  final Completer<dynamic> completer;
  _Task(this.fn, this.completer);
}
