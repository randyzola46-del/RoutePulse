import 'package:flutter/material.dart';
import '../models/vehicule.dart';
import '../theme/app_theme.dart';
import '../widgets/entretien_card.dart';

// Écran de détail d'un véhicule — correspond au PDF page 4.
class VehiculeDetailView extends StatefulWidget {
  final Vehicule vehicule;

  const VehiculeDetailView({super.key, required this.vehicule});

  @override
  State<VehiculeDetailView> createState() => _VehiculeDetailViewState();
}

class _VehiculeDetailViewState extends State<VehiculeDetailView>
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

  bool get _disponible =>
      widget.vehicule.disponibilite == DisponibiliteVehicule.disponible;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrincipal,
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApercuTab(),
                _buildMissionsTab(),
                _buildEntretienTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0x33FFB572),
            const Color(0x33FFB572),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chevron_left, color: AppColors.textMuted, size: 24),
                    Text(
                      'Véhicules',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vehicule.nomComplet,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.vehicule.type} · ${widget.vehicule.annee}',
                          style: const TextStyle(
                            color: AppColors.statusCours,
                            fontSize: 13,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge immatriculation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.statusCours.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.statusCours.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.vehicule.immatriculation,
                      style: const TextStyle(
                        color: AppColors.statusCours,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Pill disponibilité
              _StatusPill(disponible: _disponible),
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
        indicatorColor: AppColors.coral,
        indicatorWeight: 1,
        labelColor: AppColors.coral,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'Nunito',
        ),
        tabs: const [
          Tab(text: 'Aperçu'),
          Tab(text: 'Missions'),
          Tab(text: 'Entretien'),
        ],
      ),
    );
  }

  //Onglet Aperçu
  Widget _buildApercuTab() {
    final v = widget.vehicule;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Performance'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              _StatCell(
                value: '${v.livraisonsTotal}',
                label: 'Livraisons Total',
                color: AppColors.statusAttente,
              ),
              _StatCell(
                value: '${(v.livraisonsTotal > 0 ? 98 : 0)}%',
                label: 'Taux de succès',
                color: AppColors.statusLivree,
              ),
              _StatCell(
                value: '${(v.kmParcourus / 1000).toStringAsFixed(0)}k',
                label: 'km parcourus',
                color: AppColors.statusAttente,
              ),
              _StatCell(
                value: '${v.joursProchainEntretien}j',
                label: 'Prochain entretien',
                color: AppColors.statusCours,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Dernières missions'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: v.dernieresMissions
                  .map((m) => _MissionRow(mission: m))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsTab() {
    return Center(
      child: Text(
        'Missions à venir',
        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
    );
  }

  Widget _buildEntretienTab() {
    final entretiens = widget.vehicule.entretiens;

    if (entretiens.isEmpty) {
      return Center(
        child: Text(
          'Aucun entretien planifié',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontFamily: 'Nunito'),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bannière d'alerte
          EntretienAlerteBanner(entretiens: entretiens),

          // Liste des entretiens
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prochains entretiens',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 12),
                ...entretiens.map((e) => EntretienCard(item: e)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//Pill de statut
class _StatusPill extends StatelessWidget {
  final bool disponible;
  const _StatusPill({required this.disponible});

  @override
  Widget build(BuildContext context) {
    final color = disponible ? AppColors.statusLivree : AppColors.statusAnnulee;
    final label = disponible ? 'En service' : 'Hors service';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}

//Section label
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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

//Cellule stat 2×2

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
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

//Ligne de mission
class _MissionRow extends StatelessWidget {
  final MissionVehicule mission;
  const _MissionRow({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Text(
            mission.date,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              mission.chauffeur,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ),
          Text(
            '+${mission.km.toStringAsFixed(0)} km',
            style: const TextStyle(
              color: AppColors.statusAttente,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}
