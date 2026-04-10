import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicule.dart';
import '../models/livraison.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entretien_card.dart';
import '../viewmodels/vehicules_viewmodel.dart';
import '../viewmodels/livraisons_viewmodel.dart';

class VehiculeDetailView extends ConsumerStatefulWidget {
  final Vehicule vehicule;

  const VehiculeDetailView({super.key, required this.vehicule});

  @override
  ConsumerState<VehiculeDetailView> createState() => _VehiculeDetailViewState();
}

class _VehiculeDetailViewState extends ConsumerState<VehiculeDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EntretienItem> _entretiens = [];
  bool _isLoadingEntretiens = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEntretiens();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEntretiens() async {
    setState(() => _isLoadingEntretiens = true);
    try {
      final entretiens = await DatabaseService().getEntretiensByVehicule(widget.vehicule.id);
      setState(() {
        _entretiens = entretiens;
        _isLoadingEntretiens = false;
      });
    } catch (e) {
      setState(() => _isLoadingEntretiens = false);
    }
  }

  bool get _disponible =>
      widget.vehicule.disponibilite == DisponibiliteVehicule.disponible;

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'moto':
        return Icons.moped;
      case 'voiture':
        return Icons.directions_car_rounded;
      case 'fourgon':
        return Icons.local_shipping_rounded;
      default:
        return Icons.local_shipping_rounded;
    }
  }

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
                _buildEntretienTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.statusCours.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.statusCours.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      _getIconForType(widget.vehicule.type),
                      color: AppColors.statusCours,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
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
              _StatusPill(disponible: _disponible),
            ],
          ),
        ),
      ),
    );
  }

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
          Tab(text: 'Entretien'),
        ],
      ),
    );
  }

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
                value: '${v.livraisonsTotal > 0 ? ((v.livraisonsTotal - v.livraisonsMoisEnCours) / v.livraisonsTotal * 100).toStringAsFixed(0) : 0}%',
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
          const _SectionLabel('Livraisons du véhicule'),
          const SizedBox(height: 10),
          _LivraisonsVehiculeList(vehiculeId: v.id),
        ],
      ),
    );
  }

  Widget _buildEntretienTab() {
    if (_isLoadingEntretiens) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.coral),
      );
    }

    if (_entretiens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_outlined, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              'Aucun entretien planifié',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontFamily: 'Nunito'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EntretienAlerteBanner(entretiens: _entretiens),
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
                ..._entretiens.map((e) => EntretienCard(item: e)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LivraisonsVehiculeList extends ConsumerWidget {
  final String vehiculeId;

  const _LivraisonsVehiculeList({required this.vehiculeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livraisonsState = ref.watch(livraisonsViewModelProvider);

    final livraisonsVehicule = livraisonsState.livraisons
        .where((l) => l.vehiculeId == vehiculeId)
        .toList();

    if (livraisonsVehicule.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_shipping_outlined, color: AppColors.textMuted, size: 32),
              SizedBox(height: 8),
              Text(
                'Aucune livraison associée',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: livraisonsVehicule.map((livraison) {
          return _LivraisonVehiculeRow(livraison: livraison);
        }).toList(),
      ),
    );
  }
}

class _LivraisonVehiculeRow extends StatelessWidget {
  final Livraison livraison;

  const _LivraisonVehiculeRow({required this.livraison});

  Color get _statutColor => statutColor(livraison.statut);

  String get _statutLabel => livraison.statut.label;

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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _statutColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatutIcon(),
              color: _statutColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  livraison.nomClient,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  livraison.adresse,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontFamily: 'Nunito',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 10, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      livraison.creneau,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.scale, size: 10, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      '${livraison.poids.toStringAsFixed(0)} kg',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statutColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statutLabel,
              style: TextStyle(
                color: _statutColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatutIcon() {
    switch (livraison.statut) {
      case StatutLivraison.enCours:
        return Icons.play_arrow;
      case StatutLivraison.enAttente:
        return Icons.pending;
      case StatutLivraison.livree:
        return Icons.check_circle;
      case StatutLivraison.annulee:
        return Icons.cancel;
      case StatutLivraison.aReporter:
        return Icons.schedule;
    }
  }
}

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