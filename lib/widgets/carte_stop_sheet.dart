import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tsptw_service.dart';

class CarteStopSheet extends StatelessWidget {
  final RouteResult routeResult;
  final int? selectedIndex;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(int) onStopTap;

  const CarteStopSheet({
    super.key,
    required this.routeResult,
    required this.selectedIndex,
    required this.expanded,
    required this.onToggle,
    required this.onStopTap,
  });

  Color _windowColor(WindowStatus s) {
    switch (s) {
      case WindowStatus.ok:        return AppColors.statusLivree;
      case WindowStatus.warning:   return AppColors.statusCours;
      case WindowStatus.violation: return AppColors.statusReporter;
    }
  }


  String _formatMin(double min) {
    final h = min ~/ 60;
    final m = (min % 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final stops = routeResult.orderedStops;
    final infos = routeResult.arrivalInfos;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      height: expanded ? 320 : 110,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Column(
        children: [
          // Poignée + titre
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${stops.length} arrêts · ordre optimal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // Indicateur créneaux OK
                      _CreneauxBadge(
                        ok: routeResult.windowsRespected,
                        total: stops.length,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Aperçu non-expanded : barre de progression
          if (!expanded) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _RouteProgressBar(infos: infos),
            ),
          ],

          // Liste expanded
          if (expanded)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: stops.length,
                itemBuilder: (ctx, i) {
                  final stop = stops[i];
                  final info = infos[i];
                  final isSelected = selectedIndex == i;

                  return GestureDetector(
                    onTap: () => onStopTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.statusAttente.withOpacity(0.1)
                            : AppColors.bgPrincipal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.statusAttente.withOpacity(0.5)
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Numéro ordre
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _windowColor(info.status).withOpacity(0.15),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _windowColor(info.status),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Infos stop
                          // Version avec détection automatique du dépassement
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nom avec overflow détection
                                    MouseRegion(
                                      child: Container(
                                        constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                                        child: Text(
                                          stop.nomClient,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Adresse avec overflow détection
                                    Container(
                                      constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                                      child: Text(
                                        stop.adresse,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        softWrap: false,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    // Ligne des infos - peut être scrollable
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 13,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${stop.windowStart ~/ 60}h${(stop.windowStart % 60).toString().padLeft(2, '0')}–'
                                                '${stop.windowEnd ~/ 60}h${(stop.windowEnd % 60).toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.directions_car,
                                            size: 13,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${info.distFromPrev.toStringAsFixed(1)} km',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Arrivée estimée + badge
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatMin(info.arrivalMin),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _windowColor(info.status),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Barre de progression visuelle de la tournée ──────────────────────────────

class _RouteProgressBar extends StatelessWidget {
  final List<ArrivalInfo> infos;

  const _RouteProgressBar({required this.infos});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(infos.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: Colors.white.withOpacity(0.1),
            ),
          );
        }
        final idx = i ~/ 2;
        final info = infos[idx];
        Color c;
        switch (info.status) {
          case WindowStatus.ok:
            c = AppColors.statusLivree;
          case WindowStatus.warning:
            c = AppColors.statusCours;
          case WindowStatus.violation:
            c = AppColors.statusReporter;
        }
        return Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.withOpacity(0.15),
            border: Border.all(color: c, width: 1.5),
          ),
          child: Center(
            child: Text(
              '${idx + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Badge créneaux respectés ──────────────────────────────────────────────────

class _CreneauxBadge extends StatelessWidget {
  final int ok;
  final int total;

  const _CreneauxBadge({required this.ok, required this.total});

  @override
  Widget build(BuildContext context) {
    final color = ok == total ? AppColors.statusLivree : AppColors.statusCours;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$ok/$total créneaux OK',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
