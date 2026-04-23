import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/livraison.dart';
import '../models/client.dart';
import '../theme/app_theme.dart';
import '../viewmodels/livraisons_viewmodel.dart';
import '../viewmodels/clients_viewmodel.dart';

// ========== EXTENSIONS ==========

extension StatutLivraisonHelper on StatutLivraison {
  String get actionLabel {
    switch (this) {
      case StatutLivraison.enCours:
        return "Démarrer";
      case StatutLivraison.livree:
        return "Terminer";
      case StatutLivraison.annulee:
        return "Annuler";
      case StatutLivraison.aReporter:
        return "Reporter";
      case StatutLivraison.enAttente:
        return "Mettre en attente";
    }
  }

  IconData get actionIcon {
    switch (this) {
      case StatutLivraison.enCours:
        return Icons.play_arrow_rounded;
      case StatutLivraison.livree:
        return Icons.check_circle_rounded;
      case StatutLivraison.annulee:
        return Icons.cancel_rounded;
      case StatutLivraison.aReporter:
        return Icons.schedule_rounded;
      case StatutLivraison.enAttente:
        return Icons.pending_rounded;
    }
  }
}

// ========== DESIGN TOKENS ==========

class _DS {
  // Rayon
  static const r8  = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));

  // Espacement
  static const p16 = EdgeInsets.all(16);
  static const p20 = EdgeInsets.all(20);
  static const p24 = EdgeInsets.all(24);
  static const ph16 = EdgeInsets.symmetric(horizontal: 16);
  static const pv8  = EdgeInsets.symmetric(vertical: 8);

  // Typographie
  static const _base = TextStyle(fontFamily: 'Nunito');
  static TextStyle display(Color c) =>
      _base.copyWith(fontSize: 31, fontWeight: FontWeight.w900, color: c, height: 1);
  static TextStyle title(Color c) =>
      _base.copyWith(fontSize: 20, fontWeight: FontWeight.w800, color: c);
  static TextStyle heading(Color c) =>
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: c);
  static TextStyle body(Color c) =>
      _base.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: c);
  static TextStyle caption(Color c) =>
      _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: c);
}

// ========== ÉCRAN PRINCIPAL ==========

class StatsView extends ConsumerStatefulWidget {
  const StatsView({super.key});

  @override
  ConsumerState<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends ConsumerState<StatsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _periode = '7j';
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() => _tabIndex = _tabController.index));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const _periodes = [
    ('7J', '7j'), ('30J', '30j'), ('3M', '90j'), ('1A', '365j'),
  ];

  static const _tabs = [
    (Icons.grid_view_rounded,    'Global'),
    (Icons.bolt_rounded,         'Perf.'),
  ];

  @override
  Widget build(BuildContext context) {
    final livState    = ref.watch(livraisonsViewModelProvider);
    final clientState = ref.watch(clientsViewModelProvider);

    final stats = PerformanceStats.calculer(
      livraisons: livState.livraisons,
      clients:    clientState.clients,
    );

    return Scaffold(
      backgroundColor: AppColors.bgPrincipal,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            _buildPeriodeChips(),
            _buildTabSelector(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _VueGlobale(stats: stats),
                  _VuePerformance(stats: stats),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statistiques',
                    style: _DS.title(AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Aperçu complet de vos performances',
                    style: _DS.body(AppColors.textMuted)),
              ],
            ),
          ),
          // Badge temps réel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.statusLivree.withOpacity(0.12),
              borderRadius: _DS.r8,
              border: Border.all(color: AppColors.statusLivree.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.statusLivree,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('Live', style: _DS.caption(AppColors.statusLivree)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Chips de période ─────────────────────────────────────────────────────

  Widget _buildPeriodeChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: _periodes.map((p) {
          final selected = _periode == p.$2;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _periode = p.$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.coral
                      : AppColors.surface,
                  borderRadius: _DS.r12,
                  boxShadow: selected
                      ? [BoxShadow(
                    color: AppColors.coral.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )]
                      : null,
                ),
                child: Text(
                  p.$1,
                  textAlign: TextAlign.center,
                  style: _DS.caption(
                    selected ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Sélecteur d'onglets personnalisé ─────────────────────────────────────

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _tabIndex == i;
          final tab = _tabs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.surface
                      : Colors.transparent,
                  borderRadius: _DS.r12,
                  border: selected
                      ? Border.all(color: AppColors.coral.withOpacity(0.4))
                      : Border.all(color: Colors.transparent),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.$1,
                        size: 20,
                        color: selected
                            ? AppColors.coral
                            : AppColors.textMuted),
                    const SizedBox(height: 4),
                    Text(
                      tab.$2,
                      style: _DS.caption(
                        selected ? AppColors.coral : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ========== VUES DES ONGLETS ==========

class _VueGlobale extends StatelessWidget {
  final PerformanceStats stats;
  const _VueGlobale({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          const SizedBox(height: 4),
          _SectionHeader(label: 'Indicateurs clés', icon: Icons.insights_rounded),
          const SizedBox(height: 12),
          _KPIGrid(stats: stats),
          const SizedBox(height: 20),
          _SectionHeader(label: 'Évolution 7 jours', icon: Icons.show_chart_rounded),
          const SizedBox(height: 12),
          _EvolutionChart(stats: stats),
          const SizedBox(height: 20),
          _SectionHeader(label: 'Répartition', icon: Icons.donut_large_rounded),
          const SizedBox(height: 12),
          _StatutDonutChart(stats: stats),
          const SizedBox(height: 20),
          _SectionHeader(label: 'Activité journalière', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 12),
          _PerformanceJournaliere(stats: stats),
        ],
      ),
    );
  }
}

class _VuePerformance extends StatelessWidget {
  final PerformanceStats stats;
  const _VuePerformance({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        children: [
          const SizedBox(height: 4),
          _SuccessRateCard(stats: stats),
          const SizedBox(height: 16),
          _TimeMetricsCard(stats: stats),
          const SizedBox(height: 16),
          _TopClientsCard(stats: stats),
        ],
      ),
    );
  }
}

// ========== COMPOSANTS RÉUTILISABLES ==========

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.coral.withOpacity(0.12),
            borderRadius: _DS.r8,
          ),
          child: Icon(icon, color: AppColors.coral, size: 16),
        ),
        const SizedBox(width: 10),
        Text(label, style: _DS.heading(AppColors.textPrimary)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  final IconData icon;
  const _EmptyState({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(label, style: _DS.body(AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ========== KPI GRID ==========

class _KPIGrid extends StatelessWidget {
  final PerformanceStats stats;
  const _KPIGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KPICard(
                valeur: '${stats.totalLivraisons}',
                label: 'Total',
                sousLabel: 'livraisons',
                couleur: AppColors.coral,
                icone: Icons.local_shipping_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KPICard(
                valeur: '${stats.livraisonsEnCours}',
                label: 'En cours',
                sousLabel: 'maintenant',
                couleur: AppColors.statusCours,
                icone: Icons.directions_run_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KPICard(
                valeur: '${(stats.tauxReussite * 100).toStringAsFixed(1)}%',
                label: 'Réussite',
                sousLabel: '${stats.livraisonsLivrees} livrées',
                couleur: AppColors.statusLivree,
                icone: Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KPICard(
                valeur: '${(stats.tauxRetard * 100).toStringAsFixed(1)}%',
                label: 'Retard',
                sousLabel: '${stats.livraisonsRetardees} retardées',
                couleur: AppColors.statusReporter,
                icone: Icons.warning_amber_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  final String valeur;
  final String label;
  final String sousLabel;
  final Color couleur;
  final IconData icone;

  const _KPICard({
    required this.valeur,
    required this.label,
    required this.sousLabel,
    required this.couleur,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: _DS.r20,
        border: Border.all(color: couleur.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.12),
                  borderRadius: _DS.r12,
                ),
                child: Icon(icone, color: couleur, size: 18),
              ),
              // Mini trend indicator (décoratif)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  borderRadius: _DS.r8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 12, color: couleur),
                    const SizedBox(width: 2),
                    Text('+0%', style: _DS.caption(couleur)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(valeur,
              style: TextStyle(
                color: couleur,
                fontSize: 31,
                fontWeight: FontWeight.w900,
                fontFamily: 'Nunito',
                height: 1,
              )),
          const SizedBox(height: 4),
          Text(label, style: _DS.heading(AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(sousLabel, style: _DS.caption(AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ========== GRAPHIQUE ÉVOLUTION ==========

class _EvolutionChart extends StatelessWidget {
  final PerformanceStats stats;
  const _EvolutionChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxY = stats.livraisonsParJour
        .map((e) => e.count.toDouble())
        .fold(0.0, max)
        .clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: _DS.r20,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Légende
          Row(
            children: [
              Container(
                width: 28, height: 3,
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('Livraisons / jour', style: _DS.body(AppColors.textMuted)),
              const Spacer(),
              Text(
                'Moy. ${(stats.livraisonsParJour.fold(0, (s, e) => s + e.count) / stats.livraisonsParJour.length).toStringAsFixed(1)}/j',
                style: _DS.caption(AppColors.coral),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (stats.livraisonsParJour.length - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.3,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 3,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= stats.livraisonsParJour.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _dayLabel(stats.livraisonsParJour[i].date),
                            style: _DS.caption(AppColors.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: stats.livraisonsParJour.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.coral,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.coral,
                            strokeWidth: 2,
                            strokeColor: AppColors.surface,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.coral.withOpacity(0.18),
                          AppColors.coral.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.bgPrincipal,
                    tooltipBorder: BorderSide(color: AppColors.coral.withOpacity(0.3)),
                    tooltipRoundedRadius: 10,
                    getTooltipItems: (spots) => spots.map((spot) =>
                        LineTooltipItem(
                          '${spot.y.toInt()} livr.',
                          _DS.caption(AppColors.coral),
                        ),
                    ).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime date) {
    const j = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return j[date.weekday - 1];
  }
}

// ========== DONUT CHART ==========

class _StatutDonutChart extends StatelessWidget {
  final PerformanceStats stats;
  const _StatutDonutChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalLivraisons;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: _DS.r20,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Donut
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: total == 0
                        ? [
                      PieChartSectionData(
                        value: 1,
                        color: Colors.white.withOpacity(0.05),
                        radius: 28,
                        title: '',
                      )
                    ]
                        : stats.distributionParStatut.map((item) {
                      return PieChartSectionData(
                        value: item.count.toDouble(),
                        color: item.color,
                        radius: 28,
                        title: '',
                      );
                    }).toList(),
                    sectionsSpace: 3,
                    centerSpaceRadius: 44,
                    startDegreeOffset: -90,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$total',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Nunito',
                          height: 1,
                        )),
                    const SizedBox(height: 2),
                    Text('total', style: _DS.caption(AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Légende verticale
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: stats.distributionParStatut.map((item) {
                final pct = total > 0
                    ? (item.count / total * 100).toStringAsFixed(0)
                    : '0';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.statut,
                            style: _DS.body(AppColors.textMuted)),
                      ),
                      Text('$pct%',
                          style: _DS.body(AppColors.textPrimary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== BAR CHART JOURNALIER ==========

class _PerformanceJournaliere extends StatelessWidget {
  final PerformanceStats stats;
  const _PerformanceJournaliere({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxY = stats.performanceJournaliere
        .map((e) => e.livraisons.toDouble())
        .fold(0.0, max)
        .clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: _DS.r20,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Livraisons par jour', style: _DS.body(AppColors.textMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusCours.withOpacity(0.12),
                  borderRadius: _DS.r8,
                ),
                child: Text(
                  'Max ${stats.performanceJournaliere.map((e) => e.livraisons).fold(0, max)}',
                  style: _DS.caption(AppColors.statusCours),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.3,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= stats.performanceJournaliere.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _dayLabel(stats.performanceJournaliere[i].date),
                            style: _DS.caption(AppColors.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: stats.performanceJournaliere.asMap().entries.map((e) {
                  final isToday = e.value.date.day == DateTime.now().day;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.livraisons.toDouble(),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        color: isToday
                            ? AppColors.coral
                            : AppColors.coral.withOpacity(0.35),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY * 1.3,
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.bgPrincipal,
                    tooltipBorder: BorderSide(
                        color: AppColors.coral.withOpacity(0.3)),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          '${rod.toY.toInt()}',
                          _DS.caption(AppColors.coral),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const j = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return j[d.weekday - 1];
  }
}

// ========== PERFORMANCE / ONGLET 2 ==========

class _SuccessRateCard extends StatelessWidget {
  final PerformanceStats stats;
  const _SuccessRateCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: _DS.r20,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              label: 'Taux de réussite vs retard',
              icon: Icons.analytics_rounded),
          const SizedBox(height: 20),
          _GaugeRow(
            label: 'Réussite',
            value: stats.tauxReussite,
            couleur: AppColors.statusLivree,
          ),
          const SizedBox(height: 16),
          _GaugeRow(
            label: 'Retard',
            value: stats.tauxRetard,
            couleur: AppColors.statusReporter,
          ),
          const SizedBox(height: 16),
          _GaugeRow(
            label: 'Annulation',
            value: stats.totalLivraisons > 0
                ? stats.livraisonsAnnulees / stats.totalLivraisons
                : 0.0,
            couleur: AppColors.statusAnnulee,
          ),
        ],
      ),
    );
  }
}

class _GaugeRow extends StatelessWidget {
  final String label;
  final double value;
  final Color couleur;
  const _GaugeRow({
    required this.label,
    required this.value,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: _DS.body(AppColors.textMuted)),
            const Spacer(),
            Text(
              '${(v * 100).toStringAsFixed(1)}%',
              style: _DS.heading(couleur),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: _DS.r8,
          child: LinearProgressIndicator(
            value: v,
            backgroundColor: Colors.white.withOpacity(0.07),
            valueColor: AlwaysStoppedAnimation<Color>(couleur),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _TimeMetricsCard extends StatelessWidget {
  final PerformanceStats stats;
  const _TimeMetricsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: _DS.r20,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              label: 'Métriques temporelles', icon: Icons.timer_rounded),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  valeur: '${stats.tempsMoyenLivraisonMin.toStringAsFixed(0)} min',
                  label: 'Temps moyen',
                  couleur: AppColors.statusCours,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  valeur: '${(stats.tempsMoyenLivraisonMin * stats.livraisonsLivrees ~/ 60)} h',
                  label: 'Temps total',
                  couleur: AppColors.coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatTile(
            valeur: '${stats.livraisonsRetardees}',
            label: 'Livraisons en retard',
            couleur: AppColors.statusReporter,
            sousLabel: '${(stats.tauxRetard * 100).toStringAsFixed(1)}% du total',
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _TopClientsCard extends StatelessWidget {
  final PerformanceStats stats;
  const _TopClientsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: _DS.r20,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              label: 'Top clients', icon: Icons.people_rounded),
          const SizedBox(height: 16),
          if (stats.topClients.isEmpty)
            const _EmptyState(label: 'Aucun client enregistré', icon: Icons.people_rounded)
          else
            ...stats.topClients.asMap().entries.map((entry) =>
                _TopClientCard(client: entry.value, rank: entry.key + 1)
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String valeur;
  final String label;
  final Color couleur;
  final String? sousLabel;
  final bool fullWidth;

  const _StatTile({
    required this.valeur,
    required this.label,
    required this.couleur,
    this.sousLabel,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.07),
        borderRadius: _DS.r16,
        border: Border.all(color: couleur.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valeur,
                    style: TextStyle(
                      color: couleur,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Nunito',
                      height: 1,
                    )),
                const SizedBox(height: 4),
                Text(label, style: _DS.caption(AppColors.textMuted)),
                if (sousLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(sousLabel!, style: _DS.caption(couleur.withOpacity(0.7))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== CARD CLIENT ==========

class _TopClientCard extends StatelessWidget {
  final ClientStat client;
  final int rank;
  const _TopClientCard({required this.client, required this.rank});

  Color get _rangColor {
    switch (client.rang) {
      case RangClient.gold:   return const Color(0xFFFFB830);
      case RangClient.silver: return const Color(0xFFB8C0CC);
      case RangClient.bronze: return const Color(0xFFCD7F32);
      default:                return AppColors.statusAttente;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rc = _rangColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: _DS.r20,
        border: Border.all(
          color: rank <= 3
              ? rc.withOpacity(0.25)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // Numéro de rang
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? rc.withOpacity(0.15)
                  : Colors.white.withOpacity(0.06),
              borderRadius: _DS.r8,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rank <= 3 ? rc : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar initiales
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: rc.withOpacity(0.12),
              borderRadius: _DS.r12,
            ),
            child: Center(
              child: Text(
                client.nom.length >= 2
                    ? client.nom.substring(0, 2).toUpperCase()
                    : client.nom.toUpperCase(),
                style: TextStyle(
                  color: rc,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.nom, style: _DS.heading(AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_shipping_rounded,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text('${client.livraisons} livr.',
                        style: _DS.caption(AppColors.textMuted)),
                    const SizedBox(width: 10),
                    Icon(Icons.check_circle_rounded,
                        size: 11, color: AppColors.statusLivree),
                    const SizedBox(width: 3),
                    Text(
                      '${(client.tauxSucces * 100).toStringAsFixed(0)}%',
                      style: _DS.caption(AppColors.statusLivree),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Badge rang
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: rc.withOpacity(0.12),
              borderRadius: _DS.r8,
              border: Border.all(color: rc.withOpacity(0.3)),
            ),
            child: Text(
              client.rang.label,
              style: TextStyle(
                color: rc,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== MODÈLE DE DONNÉES ==========

class PerformanceStats {
  final int totalLivraisons;
  final int livraisonsLivrees;
  final int livraisonsEnCours;
  final int livraisonsRetardees;
  final int livraisonsAnnulees;
  final int livraisonsReportees;
  final double tauxReussite;
  final double tauxRetard;
  final double tempsMoyenLivraisonMin;
  final List<DailyStat> livraisonsParJour;
  final List<StatutDistribution> distributionParStatut;
  final List<ClientStat> topClients;
  final List<PerformanceJournaliere> performanceJournaliere;

  PerformanceStats({
    required this.totalLivraisons,
    required this.livraisonsLivrees,
    required this.livraisonsEnCours,
    required this.livraisonsRetardees,
    required this.livraisonsAnnulees,
    required this.livraisonsReportees,
    required this.tauxReussite,
    required this.tauxRetard,
    required this.tempsMoyenLivraisonMin,
    required this.livraisonsParJour,
    required this.distributionParStatut,
    required this.topClients,
    required this.performanceJournaliere,
  });

  factory PerformanceStats.calculer({
    required List<Livraison> livraisons,
    required List<Client> clients,
  }) {
    final livrees  = livraisons.where((l) => l.statut == StatutLivraison.livree).length;
    final enCours  = livraisons.where((l) => l.statut == StatutLivraison.enCours).length;
    final annulees = livraisons.where((l) => l.statut == StatutLivraison.annulee).length;
    final reportees= livraisons.where((l) => l.statut == StatutLivraison.aReporter).length;
    final total    = livraisons.length;

    final retardees = livraisons.where((l) {
      if (l.statut != StatutLivraison.livree && l.statut != StatutLivraison.enCours) return false;
      final heureCreation = l.dateCreation.hour;
      final (start, _)    = _parseCreneau(l.creneau);
      return heureCreation > start;
    }).length;

    final tauxReussite = total > 0 ? livrees / total : 0.0;
    final tauxRetard   = total > 0 ? retardees / total : 0.0;

    final livraisonsParJour = <DailyStat>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final count = livraisons.where((l) =>
      l.dateCreation.year  == date.year  &&
          l.dateCreation.month == date.month &&
          l.dateCreation.day   == date.day).length;
      livraisonsParJour.add(DailyStat(date: date, count: count));
    }

    final distributionParStatut = [
      StatutDistribution(statut: 'Livrées',  count: livrees,   color: AppColors.statusLivree),
      StatutDistribution(statut: 'En cours', count: enCours,   color: AppColors.statusCours),
      StatutDistribution(statut: 'Reportées',count: reportees, color: AppColors.statusReporter),
      StatutDistribution(statut: 'Annulées', count: annulees,  color: AppColors.statusAnnulee),
    ].where((s) => s.count > 0).toList();

    final topClients = clients.map((c) {
      final lc = livraisons.where((l) => l.clientId == c.id).length;
      final ts = lc > 0
          ? livraisons.where((l) => l.clientId == c.id && l.statut == StatutLivraison.livree).length / lc
          : 0.0;
      return ClientStat(nom: c.nomComplet, livraisons: lc, tauxSucces: ts, rang: c.rang);
    }).toList()
      ..sort((a, b) => b.livraisons.compareTo(a.livraisons));

    final performanceJournaliere = <PerformanceJournaliere>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final lj   = livraisons.where((l) =>
      l.dateCreation.year  == date.year  &&
          l.dateCreation.month == date.month &&
          l.dateCreation.day   == date.day).toList();
      final tmp  = lj.isEmpty
          ? 0.0
          : lj.fold(0.0, (s, l) => s + (l.nbColis * 5)) / lj.length;
      performanceJournaliere.add(PerformanceJournaliere(
          date: date, livraisons: lj.length, tempsMoyenMin: tmp));
    }

    final tempsMoyen = livrees > 0
        ? livraisons.fold(0.0, (s, l) => s + (l.nbColis * 5)) / livrees
        : 0.0;

    return PerformanceStats(
      totalLivraisons: total,
      livraisonsLivrees: livrees,
      livraisonsEnCours: enCours,
      livraisonsRetardees: retardees,
      livraisonsAnnulees: annulees,
      livraisonsReportees: reportees,
      tauxReussite: tauxReussite,
      tauxRetard: tauxRetard,
      tempsMoyenLivraisonMin: tempsMoyen,
      livraisonsParJour: livraisonsParJour,
      distributionParStatut: distributionParStatut,
      topClients: topClients.take(5).toList(),
      performanceJournaliere: performanceJournaliere,
    );
  }

  static (int, int) _parseCreneau(String creneau) {
    try {
      final parts = creneau.split(' - ');
      if (parts.length != 2) return (9, 18);
      int parse(String t) => int.tryParse(t.split(':')[0]) ?? 9;
      return (parse(parts[0]), parse(parts[1]));
    } catch (_) {
      return (9, 18);
    }
  }
}

class DailyStat {
  final DateTime date;
  final int count;
  DailyStat({required this.date, required this.count});
}

class StatutDistribution {
  final String statut;
  final int count;
  final Color color;
  StatutDistribution({required this.statut, required this.count, required this.color});
}

class ClientStat {
  final String nom;
  final int livraisons;
  final double tauxSucces;
  final RangClient rang;
  ClientStat({
    required this.nom, required this.livraisons,
    required this.tauxSucces, required this.rang,
  });
}

class PerformanceJournaliere {
  final DateTime date;
  final int livraisons;
  final double tempsMoyenMin;
  PerformanceJournaliere({
    required this.date, required this.livraisons, required this.tempsMoyenMin,
  });
}