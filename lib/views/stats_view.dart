import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/livraison.dart';
import '../models/vehicule.dart';
import '../theme/app_theme.dart';
import '../viewmodels/livraisons_viewmodel.dart';
import '../viewmodels/vehicules_viewmodel.dart';

// Écran Statistiques

class StatsView extends ConsumerWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livState = ref.watch(livraisonsViewModelProvider);
    final vehState = ref.watch(vehiculesViewModelProvider);

    final total = livState.totalLivraisons;
    final livrees = livState.countParStatut(StatutLivraison.livree);
    final enCours = livState.countParStatut(StatutLivraison.enCours);
    final enAttente = livState.countParStatut(StatutLivraison.enAttente);
    final reporter = livState.countParStatut(StatutLivraison.aReporter);
    final annulees = livState.countParStatut(StatutLivraison.annulee);
    final tauxSucces = total > 0 ? (livrees / total * 100).toStringAsFixed(0) : '0';

    final totalVehicules = vehState.vehicules.length;
    final dispo = vehState.vehicules
        .where((v) => v.disponibilite == DisponibiliteVehicule.disponible)
        .length;

    return Scaffold(
      backgroundColor: AppColors.bgPrincipal,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            const SliverToBoxAdapter(child: _StatsHeader()),

            // KPI Grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _KpiGrid(
                  total: total,
                  livrees: livrees,
                  enCours: enCours,
                  tauxSucces: tauxSucces,
                  totalVehicules: totalVehicules,
                  dispo: dispo,
                ),
              ),
            ),

            //Répartition des livraisons (Donut Chart)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionTitle('Répartition des livraisons'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _DonutChartCard(
                  total: total,
                  livrees: livrees,
                  enCours: enCours,
                  enAttente: enAttente,
                  reporter: reporter,
                  annulees: annulees,
                ),
              ),
            ),

            // Livraisons par statut (barres)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionTitle('Livraisons par statut'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              sliver: SliverToBoxAdapter(
                child: _BarChartCard(
                  bars: [
                    _BarData('Livrées', livrees, AppColors.statusLivree),
                    _BarData('En cours', enCours, AppColors.statusCours),
                    _BarData('Attente', enAttente, AppColors.statusAttente),
                    _BarData('Reporter', reporter, AppColors.statusReporter),
                    _BarData('Annulées', annulees, AppColors.statusAnnulee),
                  ],
                  total: total,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Header

class _StatsHeader extends StatelessWidget {
  const _StatsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Vue d\'ensemble de votre activité',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}

// Section title

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        fontFamily: 'Nunito',
      ),
    );
  }
}

// KPI Grid

class _KpiGrid extends StatelessWidget {
  final int total, livrees, enCours, totalVehicules, dispo;
  final String tauxSucces;

  const _KpiGrid({
    required this.total,
    required this.livrees,
    required this.enCours,
    required this.tauxSucces,
    required this.totalVehicules,
    required this.dispo,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _KpiCard(
          value: '$total',
          label: 'Total livraisons',
          color: AppColors.coral,
          icon: Icons.local_shipping_rounded,
        ),
        _KpiCard(
          value: '$tauxSucces%',
          label: 'Taux de succès',
          color: AppColors.statusLivree,
          icon: Icons.check_circle_rounded,
        ),
        _KpiCard(
          value: '$enCours',
          label: 'En cours',
          color: AppColors.statusCours,
          icon: Icons.directions_run_rounded,
        ),
        _KpiCard(
          value: '$dispo/$totalVehicules',
          label: 'Véhicules dispo',
          color: AppColors.statusAttente,
          icon: Icons.local_taxi_rounded,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData icon;

  const _KpiCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Nunito',
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Donut Chart Card

class _DonutChartCard extends StatelessWidget {
  final int total, livrees, enCours, enAttente, reporter, annulees;

  const _DonutChartCard({
    required this.total,
    required this.livrees,
    required this.enCours,
    required this.enAttente,
    required this.reporter,
    required this.annulees,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return _EmptyCard(message: 'Aucune livraison à afficher');
    }

    final slices = [
      _PieSlice('Livrées', livrees, AppColors.statusLivree),
      _PieSlice('En cours', enCours, AppColors.statusCours),
      _PieSlice('En attente', enAttente, AppColors.statusAttente),
      _PieSlice('À reporter', reporter, AppColors.statusReporter),
      _PieSlice('Annulées', annulees, AppColors.statusAnnulee),
    ].where((s) => s.count > 0).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          // Donut Chart
          SizedBox(
            height: 200,
            child: _DonutChart(slices: slices, total: total),
          ),
          const SizedBox(height: 24),
          // Légende
          Wrap(
            spacing: 16,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: slices.map((s) => _LegendItem(slice: s, total: total)).toList(),
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final List<_PieSlice> slices;
  final int total;

  const _DonutChart({required this.slices, required this.total});

  @override
  Widget build(BuildContext context) {
    double startAngle = -90; // Commencer à midi (12h)

    return CustomPaint(
      size: const Size(180, 180),
      painter: _DonutPainter(slices: slices, total: total, startAngle: startAngle),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_PieSlice> slices;
  final int total;
  final double startAngle;

  _DonutPainter({
    required this.slices,
    required this.total,
    required this.startAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final holeRadius = radius * 0.6;

    double currentAngle = startAngle;

    for (var slice in slices) {
      final sweepAngle = (slice.count / total) * 360;

      // Calculer les angles en radians
      final startRad = currentAngle * (pi / 180);
      final sweepRad = sweepAngle * (pi / 180);

      // Créer le chemin pour un anneau (donut)
      final path = Path();

      // Arc extérieur
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startRad,
        sweepRad,
        false,
      );

      final endAngleOuter = startRad + sweepRad;
      final innerStartPoint = Offset(
        center.dx + holeRadius * cos(endAngleOuter),
        center.dy + holeRadius * sin(endAngleOuter),
      );
      path.lineTo(innerStartPoint.dx, innerStartPoint.dy);

      // Arc intérieur (dans le sens inverse)
      path.arcTo(
        Rect.fromCircle(center: center, radius: holeRadius),
        endAngleOuter,
        -sweepRad,
        false,
      );

      path.close();

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      currentAngle += sweepAngle;
    }

    final centerPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, holeRadius - 1, centerPaint);

    // Texte au centre
    _drawCenterText(canvas, center, total);
  }

  void _drawCenterText(Canvas canvas, Offset center, int total) {
    final textSpan = TextSpan(
      text: '$total',
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 31,
        fontWeight: FontWeight.w900,
        fontFamily: 'Nunito',
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    final labelSpan = TextSpan(
      text: 'Total',
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Nunito',
      ),
    );

    final labelPainter = TextPainter(
      text: labelSpan,
      textDirection: TextDirection.ltr,
    );

    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, center.dy + 12),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LegendItem extends StatelessWidget {
  final _PieSlice slice;
  final int total;
  const _LegendItem({required this.slice, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = (slice.count / total * 100).toStringAsFixed(0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: slice.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${slice.label} · $pct%',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }
}

// Bar chart card

class _BarChartCard extends StatelessWidget {
  final List<_BarData> bars;
  final int total;
  const _BarChartCard({required this.bars, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return _EmptyCard(message: 'Pas encore de données');
    }

    final maxVal = bars.map((b) => b.value).fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          final ratio = maxVal > 0 ? bar.value / maxVal : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${bar.value}',
                    style: TextStyle(
                      color: bar.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 80 * ratio + 4,
                      color: bar.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bar.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Empty state

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 16,
            fontFamily: 'Nunito',
          ),
        ),
      ),
    );
  }
}

// Modèles internes
class _PieSlice {
  final String label;
  final int count;
  final Color color;
  const _PieSlice(this.label, this.count, this.color);
}

class _BarData {
  final String label;
  final int value;
  final Color color;
  const _BarData(this.label, this.value, this.color);
}