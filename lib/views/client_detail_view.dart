import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';
import '../models/livraison.dart';
import '../theme/app_theme.dart';
import '../viewmodels/livraisons_viewmodel.dart';
import '../widgets/livraison_form_sheet.dart';

class ClientDetailView extends ConsumerStatefulWidget {
  final Client client;
  const ClientDetailView({super.key, required this.client});

  @override
  ConsumerState<ClientDetailView> createState() => _ClientDetailViewState();
}

class _ClientDetailViewState extends ConsumerState<ClientDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await ref.read(livraisonsViewModelProvider.notifier).chargerLivraisons();
  }

  List<Livraison> _getLivraisonsClient() {
    final toutes = ref.watch(livraisonsViewModelProvider).livraisons;
    final clientId = widget.client.id;
    final nomClient = widget.client.nomComplet.toLowerCase();

    return toutes.where((l) {
      final matchId = l.clientId == clientId;
      final matchNom = l.nomClient.toLowerCase() == nomClient;
      return matchId || matchNom;
    }).toList()
      ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
  }

  Color get _avatarColor {
    switch (widget.client.rang) {
      case RangClient.gold:     return AppColors.coral;
      case RangClient.silver:   return AppColors.statusLivree;
      case RangClient.bronze:   return AppColors.statusCours;
      case RangClient.standard: return AppColors.statusAttente;
    }
  }

  void _callClient() {
    if (widget.client.phone != null && widget.client.phone!.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.statusLivree.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone, color: AppColors.statusLivree, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Contacter le client',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.client.nomComplet,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  widget.client.phone!,
                  style: const TextStyle(
                    color: AppColors.statusLivree,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
              ),
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Fonction d\'appel à implémenter'),
                    backgroundColor: AppColors.surface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Appeler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusLivree,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aucun numéro de téléphone enregistré pour ce client'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showNewDeliverySheet() {
    final prefill = ClientPrefill(
      nom: widget.client.nomComplet,
      adresse: widget.client.adresse,
      creneauPrefere: widget.client.creneauPrefere,
      phone: widget.client.phone,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LivraisonFormSheet(
        prefillClient: prefill,
      ),
    ).then((_) {
      _refreshData();
    });
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
                _buildInfosTab(),
                _buildHistoriqueTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final c = widget.client;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.bgPrincipal,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface2.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.chevron_left, color: AppColors.textMuted, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Retour',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showNewDeliverySheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.statusLivree, AppColors.statusLivree.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.statusLivree.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Livraison',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (c.phone != null && c.phone!.isNotEmpty)
                    GestureDetector(
                      onTap: _callClient,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.coral.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone, size: 14, color: AppColors.coral),
                            SizedBox(width: 6),
                            Text(
                              'Appeler',
                              style: TextStyle(
                                color: AppColors.coral,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_avatarColor, _avatarColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _avatarColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      c.initiales,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.nomComplet,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _avatarColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                c.estRecurrent ? Icons.star : Icons.star_border,
                                size: 12,
                                color: _avatarColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                c.estRecurrent ? 'Client récurrent' : 'Client occasionnel',
                                style: TextStyle(
                                  color: _avatarColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                c.adresse,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (c.phone != null && c.phone!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 12, color: AppColors.statusLivree),
                              const SizedBox(width: 4),
                              Text(
                                c.phone!,
                                style: const TextStyle(
                                  color: AppColors.statusLivree,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _KpiBox(
                    value: '${c.livraisonsTotal}',
                    label: 'Livraisons',
                    icon: Icons.local_shipping_outlined,
                  ),
                  const SizedBox(width: 12),
                  _KpiBox(
                    value: '${(c.tauxSucces * 100).toStringAsFixed(0)}%',
                    label: 'Succès',
                    icon: Icons.verified_outlined,
                    valueColor: AppColors.statusLivree,
                  ),
                  const SizedBox(width: 12),
                  _KpiBox(
                    value: c.creneauPrefere.split(' - ').first,
                    label: 'Créneau',
                    icon: Icons.schedule_outlined,
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.coral.withOpacity(0.15),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.coral,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Infos'),
          Tab(text: 'Historique'),
        ],
      ),
    );
  }

  Widget _buildInfosTab() {
    final c = widget.client;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _InfoCard(
            icon: Icons.badge_outlined,
            label: 'ID Client',
            value: c.id,
            copyable: true,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.person_outline,
            label: 'Nom complet',
            value: c.nomComplet,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.location_on_outlined,
            label: 'Adresse',
            value: c.adresse,
            multiline: true,
          ),
          if (c.phone != null && c.phone!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.phone_outlined,
              label: 'Téléphone',
              value: c.phone!,
              action: _CallButton(onPressed: _callClient),
            ),
          ],
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.emoji_events_outlined,
            label: 'Rang',
            value: c.rang.label,
            valueColor: _getRangColor(c.rang),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: c.estRecurrent ? Icons.star : Icons.star_border,
            label: 'Type',
            value: c.estRecurrent ? 'Client récurrent' : 'Client occasionnel',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.local_shipping_outlined,
            label: 'Total livraisons',
            value: '${c.livraisonsTotal}',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.verified_outlined,
            label: 'Taux de succès',
            value: '${(c.tauxSucces * 100).toStringAsFixed(0)}%',
            valueColor: AppColors.statusLivree,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.schedule_outlined,
            label: 'Créneau préféré',
            value: c.creneauPrefere,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.calendar_today_outlined,
            label: 'Date création',
            value: _formatDate(c.dateCreation),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.notes_outlined,
            label: 'Notes',
            value: c.notes ?? 'Aucune note',
            multiline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoriqueTab() {
    final isLoading = ref.watch(livraisonsViewModelProvider).isLoading;
    final livraisons = _getLivraisonsClient();

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.coral),
      );
    }

    if (livraisons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune livraison',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ce client n\'a pas encore de livraisons',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // Group livraisons by month
    final Map<String, List<Livraison>> grouped = {};
    for (final l in livraisons) {
      final key = _formatMonth(l.dateCreation);
      grouped.putIfAbsent(key, () => []).add(l);
    }

    // Sort groups by most recent date
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aDate = livraisons.firstWhere((l) => _formatMonth(l.dateCreation) == a).dateCreation;
        final bDate = livraisons.firstWhere((l) => _formatMonth(l.dateCreation) == b).dateCreation;
        return bDate.compareTo(aDate);
      });

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.coral,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final monthKey = sortedKeys[index];
          final items = grouped[monthKey]!
            ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      monthKey,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map((livraison) => _LivraisonHistoriqueCard(
                livraison: livraison,
                formatDate: _formatDate,
              )),
            ],
          );
        },
      ),
    );
  }

  String _formatMonth(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Color _getRangColor(RangClient rang) {
    switch (rang) {
      case RangClient.gold: return const Color(0xFFFFB830);
      case RangClient.silver: return const Color(0xFFB8C0CC);
      case RangClient.bronze: return const Color(0xFFCD7F32);
      default: return AppColors.statusAttente;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ========== WIDGETS ==========

class _KpiBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color valueColor;

  const _KpiBox({
    required this.value,
    required this.label,
    required this.icon,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: valueColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? action;
  final bool copyable;
  final bool multiline;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.action,
    this.copyable = false,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.coral.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.coral),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: multiline ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    height: multiline ? 1.3 : 1,
                  ),
                  maxLines: multiline ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (action != null) action!,
          if (copyable)
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copié'),
                    backgroundColor: AppColors.surface,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.copy, size: 16, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _LivraisonHistoriqueCard extends StatelessWidget {
  final Livraison livraison;
  final String Function(DateTime) formatDate;

  const _LivraisonHistoriqueCard({
    required this.livraison,
    required this.formatDate,
  });

  Color get _statutColor {
    switch (livraison.statut) {
      case StatutLivraison.livree:    return AppColors.statusLivree;
      case StatutLivraison.enCours:   return AppColors.statusCours;
      case StatutLivraison.annulee:   return AppColors.coral;
      case StatutLivraison.aReporter: return AppColors.statusAttente;
      case StatutLivraison.enAttente: return AppColors.textMuted;
    }
  }

  IconData get _statutIcon {
    switch (livraison.statut) {
      case StatutLivraison.livree:    return Icons.check_circle_outline;
      case StatutLivraison.enCours:   return Icons.local_shipping_outlined;
      case StatutLivraison.annulee:   return Icons.cancel_outlined;
      case StatutLivraison.aReporter: return Icons.schedule_outlined;
      case StatutLivraison.enAttente: return Icons.hourglass_empty_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Statut icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _statutColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statutIcon, size: 20, color: _statutColor),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        livraison.adresse,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statutColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        livraison.statut.label,
                        style: TextStyle(
                          color: _statutColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${livraison.nbColis} colis • ${livraison.poids.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      livraison.creneau,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(livraison.dateCreation),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (livraison.notes != null && livraison.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.bgPrincipal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notes_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            livraison.notes!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CallButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.statusLivree, AppColors.statusLivree.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_rounded, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Appeler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}