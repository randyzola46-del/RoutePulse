import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicule.dart';
import '../models/client.dart';
import '../theme/app_theme.dart';
import '../viewmodels/vehicules_viewmodel.dart';
import '../viewmodels/clients_viewmodel.dart';
import '../widgets/vehicule_card.dart';
import '../widgets/client_row.dart';
import 'vehicule_detail_view.dart';
import 'client_detail_view.dart';

class GestionView extends ConsumerStatefulWidget {
  const GestionView({super.key});

  @override
  ConsumerState<GestionView> createState() => _GestionViewState();
}

class _GestionViewState extends ConsumerState<GestionView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      animationDuration: const Duration(milliseconds: 300), // 👈
    );
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrincipal,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            _buildTopTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(), // 👈
                children: [
                  _VehiculesTab(),
                  _ClientsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabBar() {
    return Container(
      color: AppColors.bgPrincipal,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(0),
              child: AnimatedContainer( // 👈
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _tabController.index == 0
                          ? AppColors.statusCours
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping_rounded,
                      color: _tabController.index == 0
                          ? AppColors.statusCours
                          : AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Véhicules',
                      style: TextStyle(
                        color: _tabController.index == 0
                            ? AppColors.statusCours
                            : AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(1),
              child: AnimatedContainer( // 👈
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _tabController.index == 1
                          ? AppColors.statusAttente
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_rounded,
                      color: _tabController.index == 1
                          ? AppColors.statusAttente
                          : AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Clients',
                      style: TextStyle(
                        color: _tabController.index == 1
                            ? AppColors.statusAttente
                            : AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ONGLET VÉHICULES
class _VehiculesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehiculesViewModelProvider);
    final vm = ref.read(vehiculesViewModelProvider.notifier);

    return Column(
      children: [
        _VehiculesHeader(
          count: state.vehicules.length,
          onAjouter: () {/* TODO */},
        ),
        _SearchBar(
          hintText: 'Rechercher un véhicule...',
          onChanged: vm.setRecherche,
          accentColor: AppColors.coralLight,
        ),
        _VehiculesFilterTabs(
          filtre: state.filtreDisponibilite,
          onSelect: vm.setFiltreDisponibilite,
        ),
        Expanded(
          child: state.vehiculesFiltres.isEmpty
              ? const _EmptyState(
            icon: Icons.local_shipping_outlined,
            message: 'Aucun véhicule',
            sub: 'Ajoutez votre premier véhicule',
          )
              : ListView.builder(
            padding: const EdgeInsets.only(bottom: 24, top: 4),
            itemCount: state.vehiculesFiltres.length,
            itemBuilder: (ctx, i) {
              final v = state.vehiculesFiltres[i];
              return VehiculeCard(
                vehicule: v,
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => VehiculeDetailView(vehicule: v),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VehiculesHeader extends StatelessWidget {
  final int count;
  final VoidCallback onAjouter;

  const _VehiculesHeader({required this.count, required this.onAjouter});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x33FFB572), Color(0x33FFB572)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.statusCours.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.statusCours.withOpacity(0.28),
              ),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: AppColors.statusCours,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Véhicules',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$count véhicule${count > 1 ? "s" : ""} enregistré${count > 1 ? "s" : ""}',
                      style: const TextStyle(
                        color: AppColors.statusCours,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onAjouter,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.statusCours,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Ajouter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehiculesFilterTabs extends StatelessWidget {
  final DisponibiliteVehicule? filtre;
  final ValueChanged<DisponibiliteVehicule?> onSelect;

  const _VehiculesFilterTabs({required this.filtre, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = <DisponibiliteVehicule?>[
      null,
      ...DisponibiliteVehicule.values
    ];
    final labels = ['Tous', 'Disponible', 'Indisponible'];

    return Container(
      color: AppColors.bgPrincipal,
      child: Row(
        children: List.generate(options.length, (i) {
          final isActive = filtre == options[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(options[i]),
              child: AnimatedContainer( // 👈
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppColors.coral : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? AppColors.coral : AppColors.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ONGLET CLIENTS
class _ClientsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientsViewModelProvider);
    final vm = ref.read(clientsViewModelProvider.notifier);

    return Column(
      children: [
        _ClientsHeader(
          count: state.clients.length,
          onAjouter: () {/* TODO */},
        ),
        _SearchBar(
          hintText: 'Rechercher un client...',
          onChanged: vm.setRecherche,
          accentColor: AppColors.coralLight,
        ),
        _ClientsFilterTabs(
          filtre: state.filtre,
          onSelect: vm.setFiltre,
        ),
        Expanded(
          child: state.clientsFiltres.isEmpty
              ? const _EmptyState(
            icon: Icons.group_outlined,
            message: 'Aucun client',
            sub: 'Ajoutez votre premier client',
          )
              : Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ListView.builder(
                shrinkWrap: false,
                padding: EdgeInsets.zero,
                itemCount: state.clientsFiltres.length,
                itemBuilder: (ctx, i) {
                  final c = state.clientsFiltres[i];
                  return ClientRow(
                    client: c,
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => ClientDetailView(client: c),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ClientsHeader extends StatelessWidget {
  final int count;
  final VoidCallback onAjouter;

  const _ClientsHeader({required this.count, required this.onAjouter});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x339288E0), Color(0x339288E0)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.statusAttente.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.statusAttente.withOpacity(0.25),
              ),
            ),
            child: const Icon(
              Icons.group_rounded,
              color: AppColors.statusAttente,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clients',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$count client${count > 1 ? "s" : ""} récurrent${count > 1 ? "s" : ""}',
                      style: const TextStyle(
                        color: AppColors.statusAttente,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onAjouter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.statusAttente,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.statusAttente.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Nouveau',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClientsFilterTabs extends StatelessWidget {
  final FiltreClients filtre;
  final ValueChanged<FiltreClients> onSelect;

  const _ClientsFilterTabs({required this.filtre, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = FiltreClients.values;
    final labels = ['Top clients', 'Récents', 'Inactifs'];

    return Container(
      color: AppColors.bgPrincipal,
      child: Row(
        children: List.generate(options.length, (i) {
          final isActive = filtre == options[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(options[i]),
              child: AnimatedContainer( // 👈
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? AppColors.statusLivree
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.statusLivree
                        : AppColors.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// WIDGETS PARTAGÉS

class _SearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final Color accentColor;

  const _SearchBar({
    required this.hintText,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontFamily: 'Nunito',
        ),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon:
          Icon(Icons.search_rounded, color: accentColor, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
            BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontFamily: 'Nunito',
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.coral.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppColors.coral, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}