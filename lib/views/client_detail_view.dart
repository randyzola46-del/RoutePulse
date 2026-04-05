import 'package:flutter/material.dart';
import '../models/client.dart';
import '../theme/app_theme.dart';

//Écran de détail d'un client
class ClientDetailView extends StatefulWidget {
  final Client client;
  const ClientDetailView({super.key, required this.client});

  @override
  State<ClientDetailView> createState() => _ClientDetailViewState();
}

class _ClientDetailViewState extends State<ClientDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _avatarColor {
    switch (widget.client.rang) {
      case RangClient.gold:     return AppColors.coral;
      case RangClient.silver:   return AppColors.statusLivree;
      case RangClient.bronze:   return AppColors.statusCours;
      case RangClient.standard: return AppColors.statusAttente;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrincipal,
      body: Column(
        children: [
          _buildHero(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoriqueTab(),
                _buildInfosTab(),
                _buildNotesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Hero
  Widget _buildHero(BuildContext context) {
    final c = widget.client;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF172B26), Color(0xFF1C3530), Color(0xFF1F1D2B)],
          stops: [0, 0.6, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chevron_left, color: AppColors.textMuted, size: 20),
                    Text(
                      'Clients',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _avatarColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.statusCours, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c.initiales,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.nomComplet,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Client ${c.rang.label} · ${c.estRecurrent ? "Récurrent" : "Occasionnel"}',
                          style: const TextStyle(
                            color: AppColors.statusLivree,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.adresse,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // KPI row
              Row(
                children: [
                  _KpiBox(value: '${c.livraisonsTotal}', label: 'Livraisons'),
                  const SizedBox(width: 8),
                  _KpiBox(
                    value: '${(c.tauxSucces * 100).toStringAsFixed(0)}%',
                    label: 'Succès',
                    valueColor: AppColors.statusLivree,
                  ),
                  const SizedBox(width: 8),
                  _KpiBox(
                    value: c.creneauPrefere,
                    label: 'Créneau',
                    valueColor: AppColors.statusCours,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Tab bar
  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.statusLivree,
        indicatorWeight: 2,
        labelColor: AppColors.statusLivree,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontFamily: 'Nunito',
        ),
        tabs: const [
          Tab(text: 'Historique'),
          Tab(text: 'Infos'),
          Tab(text: 'Notes'),
        ],
      ),
    );
  }

  //Onglet Historique (timeline)

  Widget _buildHistoriqueTab() {
    final history = widget.client.historique;
    if (history.isEmpty) {
      return const Center(
        child: Text(
          'Aucun historique',
          style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito'),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'MARS 2026',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontFamily: 'Nunito',
            ),
          ),
        ),
        ...List.generate(history.length, (i) {
          return _TimelineItem(
            item: history[i],
            isLast: i == history.length - 1,
          );
        }),
      ],
    );
  }

  Widget _buildInfosTab() {
    return Center(
      child: Text(
        'Informations client',
        style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito'),
      ),
    );
  }

  Widget _buildNotesTab() {
    return Center(
      child: Text(
        'Notes & commentaires',
        style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito'),
      ),
    );
  }
}

// ── KPI box ───────────────────────────────────────────────────────────────────

class _KpiBox extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _KpiBox({
    required this.value,
    required this.label,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Timeline item ─────────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  final HistoriqueLivraison item;
  final bool isLast;

  const _TimelineItem({required this.item, required this.isLast});

  Color get _dotColor {
    switch (item.statut) {
      case StatutHistorique.livree:   return AppColors.statusLivree;
      case StatutHistorique.reportee: return AppColors.statusCours;
      case StatutHistorique.echouee:  return AppColors.statusAnnulee;
    }
  }

  Color get _badgeColor => _dotColor;

  String get _icon {
    switch (item.statut) {
      case StatutHistorique.livree:   return '✓';
      case StatutHistorique.reportee: return '!';
      case StatutHistorique.echouee:  return '✕';
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colonne timeline (dot + ligne)
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _dotColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _icon,
                    style: TextStyle(
                      color: _dotColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Contenu
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.date,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.adresse,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.statut.label,
                      style: TextStyle(
                        color: _badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
