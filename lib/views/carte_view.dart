// lib/views/carte_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../models/livraison.dart';
import '../theme/app_theme.dart';
import '../viewmodels/carte_viewmodel.dart';
import '../services/tsptw_service.dart';
import '../services/location_service.dart';
import '../widgets/carte_stop_sheet.dart';

class CarteView extends ConsumerStatefulWidget {
  const CarteView({super.key});

  @override
  ConsumerState<CarteView> createState() => _CarteViewState();
}

class _CarteViewState extends ConsumerState<CarteView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _mapController = MapController();
  bool _sheetExpanded = false;
  int? _selectedStopIndex;
  bool _mapReady = false;

  ll.LatLng _toLl(LatLng p) => ll.LatLng(p.lat, p.lng);

  Color _windowColor(WindowStatus s) {
    switch (s) {
      case WindowStatus.ok:
        return AppColors.statusLivree;
      case WindowStatus.warning:
        return AppColors.statusCours;
      case WindowStatus.violation:
        return AppColors.statusReporter;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(carteViewModelProvider);
    final vm = ref.read(carteViewModelProvider.notifier);

    final route = state.routeResult;
    final geometry = state.osrmGeometry;
    final origin = state.userLocation;

    // Centre par défaut : Antananarivo si pas encore localisé
    final center = origin ?? const LatLng(-18.9126, 47.5079);

    return Scaffold(
      backgroundColor: AppColors.bgPrincipal,
      body: Stack(
        children: [
          // ── Carte OpenStreetMap ─────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _toLl(center),
              initialZoom: 13,
              backgroundColor: AppColors.bgPrincipal,
              onMapReady: () {
                setState(() => _mapReady = true);
                // Dès que la carte est prête et qu'on a la position → centrer
                if (origin != null) {
                  _fitBounds(origin, route);
                }
              },
            ),
            children: [
              // Tuiles OSM avec filtre sombre
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.routepulse.app',
                tileBuilder: _darkTile,
              ),

              // Cercle de précision GPS
              if (origin != null &&
                  state.locationAccuracyM != null &&
                  state.locationAccuracyM! < 500)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _toLl(origin),
                      radius: state.locationAccuracyM!,
                      useRadiusInMeter: true,
                      color: AppColors.statusLivree.withOpacity(0.08),
                      borderColor: AppColors.statusLivree.withOpacity(0.3),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),

              // Polyligne de l'itinéraire OSRM
              if (geometry != null && geometry.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: geometry.map(_toLl).toList(),
                      color: AppColors.coral.withOpacity(0.9),
                      strokeWidth: 4.5,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),

              // Marqueurs
              MarkerLayer(
                markers: [
                  // Position utilisateur réelle
                  if (origin != null)
                    Marker(
                      point: _toLl(origin),
                      width: 44,
                      height: 44,
                      child: _UserMarker(
                        isReal: state.hasRealLocation,
                        source: state.locationSource,
                      ),
                    ),

                  // Stops optimisés
                  if (route != null)
                    ...List.generate(route.orderedStops.length, (i) {
                      final stop = route.orderedStops[i];
                      final info = route.arrivalInfos[i];
                      return Marker(
                        point: _toLl(stop.position),
                        width: 44,
                        height: 52,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedStopIndex = i;
                              _sheetExpanded = true;
                            });
                            _mapController.move(_toLl(stop.position), 15);
                          },
                          child: _StopMarker(
                            rank: i + 1,
                            statusColor: _windowColor(info.status),
                            selected: _selectedStopIndex == i,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),

          // ── Header KPI flottant ──────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _MapHeader(
              state: state,
              onRefresh: () {
                setState(() {
                  _selectedStopIndex = null;
                  _sheetExpanded = false;
                });
                vm.optimizeRoute();
              },
              onRelocate: () => vm.relocateAndRefresh(),
            ),
          ),

          // ── Alerte GPS refusé ────────────────────────────────────────────
          if (state.locationSource == LocationSource.denied ||
              state.locationSource == LocationSource.unavailable)
            Positioned(
              top: MediaQuery.of(context).padding.top + 110,
              left: 16,
              right: 16,
              child: const _GpsAlert(),
            ),

          // ── Alerte Fallback (mode démo) ───────────────────────────────────
          if (state.locationSource == LocationSource.fallback)
            Positioned(
              top: MediaQuery.of(context).padding.top + 110,
              left: 16,
              right: 16,
              child: const _FallbackAlert(),
            ),

          // ── NOUVEAU : Menu flottant avec boutons optimisés ────────────────
          Positioned(
            right: 16,
            bottom: _sheetExpanded ? 340 : 130,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton Optimisation (principal)
                _FloatingActionButton(
                  icon: Icons.route,
                  label: 'Optimiser',
                  color: AppColors.coral,
                  onTap: () {
                    setState(() {
                      _selectedStopIndex = null;
                      _sheetExpanded = false;
                    });
                    vm.optimizeRoute();
                  },
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: 12),
                // Bouton Localisation
                _FloatingActionButton(
                  icon: Icons.emoji_people,
                  label: 'Me localiser',
                  color: AppColors.statusLivree,
                  onTap: () {
                    if (origin != null) {
                      _mapController.move(_toLl(origin), 15);
                    } else {
                      vm.relocateAndRefresh();
                    }
                  },
                  isLoading: state.status == MapStatus.locating,
                ),
              ],
            ),
          ),

          // ── Bottom sheet ─────────────────────────────────────────────────
          if (route != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CarteStopSheet(
                routeResult: route,
                selectedIndex: _selectedStopIndex,
                expanded: _sheetExpanded,
                onToggle: () => setState(() => _sheetExpanded = !_sheetExpanded),
                onStopTap: (i) {
                  setState(() => _selectedStopIndex = i);
                  _mapController.move(
                    _toLl(route.orderedStops[i].position),
                    15,
                  );
                },
              ),
            ),

          // ── Overlay de chargement avec étapes ───────────────────────────
          if (state.isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 110,
              left: 0,
              right: 0,
              child: Center(
                child: _LoadingOverlay(state: state),
              ),
            ),

          // ── Message vide (NOUVEAU : avec carte de fond améliorée) ────────
          if (state.status == MapStatus.idle && route == null)
            const Positioned.fill(
              child: Center(
                child: _EmptyState(),
              ),
            ),

          // ── Erreur ───────────────────────────────────────────────────────
          if (state.status == MapStatus.error)
            Positioned(
              top: MediaQuery.of(context).padding.top + 110,
              left: 16,
              right: 16,
              child: _ErrorBanner(
                  message: state.errorMessage ?? 'Erreur inconnue'),
            ),
        ],
      ),
    );
  }

  // ✅ FONCTION CORRIGÉE - Utilise CameraFit.coordinates au lieu de LatLngBounds
  void _fitBounds(LatLng origin, RouteResult? route) {
    if (!_mapReady) return;

    final List<ll.LatLng> points = [];

    // Ajouter l'origine
    points.add(_toLl(origin));

    // Ajouter tous les stops
    if (route != null) {
      for (final stop in route.orderedStops) {
        points.add(_toLl(stop.position));
      }
    }

    if (points.isEmpty) {
      _mapController.move(_toLl(origin), 14);
      return;
    }

    // Ajuster la caméra pour voir tous les points
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(40, 120, 40, 160),
      ),
    );
  }

  Widget _darkTile(BuildContext context, Widget tile, TileImage img) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -0.75, 0, 0, 0, 230,
        0, -0.75, 0, 0, 230,
        0, 0, -0.75, 0, 230,
        0, 0, 0, 1, 0,
      ]),
      child: tile,
    );
  }
}

// ─── NOUVEAU : Bouton flottant amélioré avec label ───────────────────────────

class _FloatingActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _FloatingActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.95),
              color,
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isLoading ? 0 : 1,
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets existants (gardés tels quels) ───────────────────────────────────

class _UserMarker extends StatelessWidget {
  final bool isReal;
  final LocationSource? source;

  const _UserMarker({required this.isReal, this.source});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    if (source == LocationSource.fallback) {
      color = AppColors.statusAttente;
      icon = Icons.location_city;
    } else if (isReal) {
      color = AppColors.statusLivree;
      icon = Icons.my_location;
    } else {
      color = AppColors.statusCours;
      icon = Icons.location_searching;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _StopMarker extends StatelessWidget {
  final int rank;
  final Color statusColor;
  final bool selected;

  const _StopMarker({
    required this.rank,
    required this.statusColor,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: selected ? 40 : 32,
          height: selected ? 40 : 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
            border: Border.all(
              color: selected ? Colors.white : Colors.white54,
              width: selected ? 2.5 : 1.5,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: statusColor.withOpacity(0.5),
                blurRadius: 14,
                spreadRadius: 2,
              )
            ]
                : [],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                color: Colors.white,
                fontSize: selected ? 14 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 6),
          painter: _PinTail(color: statusColor),
        ),
      ],
    );
  }
}

class _InactiveStopMarker extends StatelessWidget {
  final String clientName;
  final StatutLivraison statut;

  const _InactiveStopMarker({
    required this.clientName,
    required this.statut,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (statut) {
      case StatutLivraison.livree:
        color = AppColors.statusLivree;
        break;
      case StatutLivraison.annulee:
        color = AppColors.statusAnnulee;
        break;
      case StatutLivraison.aReporter:
        color = AppColors.statusReporter;
        break;
      default:
        color = AppColors.textMuted;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.3),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Center(
        child: Icon(
          Icons.circle,
          color: color,
          size: 8,
        ),
      ),
    );
  }
}

class _PinTail extends CustomPainter {
  final Color color;
  const _PinTail({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PinTail o) => o.color != color;
}

class _MapHeader extends StatelessWidget {
  final CarteState state;
  final VoidCallback onRefresh;
  final VoidCallback onRelocate;

  const _MapHeader({
    required this.state,
    required this.onRefresh,
    required this.onRelocate,
  });

  @override
  Widget build(BuildContext context) {
    final route = state.routeResult;
    final h = state.displayDuration ~/ 60;
    final m = (state.displayDuration % 60).round();
    final timeStr = h > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '${m}min';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GpsIndicator(
                source: state.locationSource,
                accuracyM: state.locationAccuracyM,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tournée optimisée · TSPTW + OSRM',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Les boutons ont été déplacés vers le FAB, on garde juste le badge
              const SizedBox(width: 6),
            ],
          ),
          if (route != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _KpiChip(
                  icon: Icons.location_on_outlined,
                  value: '${route.orderedStops.length} arrêts',
                  color: AppColors.statusAttente,
                ),
                const SizedBox(width: 6),
                _KpiChip(
                  icon: Icons.route_outlined,
                  value: '${state.displayDistance.toStringAsFixed(1)} km',
                  color: AppColors.coral,
                ),
                const SizedBox(width: 6),
                _KpiChip(
                  icon: Icons.schedule_outlined,
                  value: timeStr,
                  color: AppColors.statusCours,
                ),
                const SizedBox(width: 6),
                _KpiChip(
                  icon: Icons.check_circle_outline,
                  value: '${route.windowsRespected}/${route.orderedStops.length} OK',
                  color: AppColors.statusLivree,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GpsIndicator extends StatelessWidget {
  final LocationSource? source;
  final double? accuracyM;

  const _GpsIndicator({this.source, this.accuracyM});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String tooltip;

    switch (source) {
      case LocationSource.gps:
        color = AppColors.statusLivree;
        icon = Icons.gps_fixed;
        tooltip = accuracyM != null
            ? 'GPS · ±${accuracyM!.round()}m'
            : 'GPS actif';
        break;
      case LocationSource.network:
        color = AppColors.statusCours;
        icon = Icons.gps_not_fixed;
        tooltip = 'Réseau · précision faible';
        break;
      case LocationSource.denied:
        color = AppColors.statusReporter;
        icon = Icons.gps_off;
        tooltip = 'Permission refusée';
        break;
      case LocationSource.unavailable:
        color = AppColors.textMuted;
        icon = Icons.location_disabled;
        tooltip = 'GPS désactivé';
        break;
      case LocationSource.fallback:
        color = AppColors.statusAttente;
        icon = Icons.location_city;
        tooltip = 'Position par défaut (démo)';
        break;
      default:
        color = AppColors.textMuted;
        icon = Icons.location_searching;
        tooltip = 'Localisation...';
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 16),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _KpiChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final CarteState state;
  const _LoadingOverlay({required this.state});

  String get _label {
    switch (state.status) {
      case MapStatus.locating:
        return 'Localisation GPS...';
      case MapStatus.geocoding:
        final p = state.geocodingProgress;
        if (p != null) return p.label;
        return 'Géocodage des adresses...';
      case MapStatus.computing:
        return 'Optimisation TSPTW...';
      case MapStatus.fetchingRoute:
        return 'Calcul route OSRM...';
      default:
        return 'Chargement...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = state.geocodingProgress;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.coral,
                  value: progress?.fraction,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.fraction,
              backgroundColor: Colors.white.withOpacity(0.08),
              color: AppColors.coral,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              '${progress.done}/${progress.total} adresses',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GpsAlert extends StatelessWidget {
  const _GpsAlert();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusReporterTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusReporter.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off,
              color: AppColors.statusReporter, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Localisation GPS indisponible. Activez-la dans les paramètres pour une optimisation précise.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.statusReporter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackAlert extends StatelessWidget {
  const _FallbackAlert();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusAttente.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusAttente.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: AppColors.statusAttente, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Mode démo : Position par défaut (Antananarivo). Activez le GPS pour une vraie optimisation.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.statusAttente,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusAnnulee.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusAnnulee.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.statusAnnulee, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.statusAnnulee,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── NOUVEAU : EmptyState amélioré avec carte de fond ────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.surface.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.coral.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône principale avec fond
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.coral,
                    AppColors.coral.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.coral.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            const Text(
              'Vous n\'avez pas encore de livraison en cours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description détaillée
            Container(
              constraints: const BoxConstraints(maxWidth: 260),
              child: const Text(
                'Ajoutez des points de livraison pour générer un parcours optimisé avec calcul des fenêtres horaires.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour les étapes
class _StepItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StepItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSub,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}