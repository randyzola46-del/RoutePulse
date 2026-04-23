// lib/views/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../providers/navigation_provider.dart';
import '../providers/carte_controller_provider.dart';
import 'dashboard_view.dart';
import 'livraisons_list_view.dart';
import 'carte_view.dart';
import 'gestion_view.dart';
import 'stats_view.dart';
import '../widgets/app_drawer.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final CarteController _carteController;

  @override
  void initState() {
    super.initState();
    _carteController = CarteController();
  }

  @override
  void dispose() {
    _carteController.dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    ref.read(navigationProvider.notifier).setTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).user;
    final navState = ref.watch(navigationProvider);
    final currentIndex = navState.selectedTab;

    return ProviderScope(
      overrides: [
        carteControllerProvider.overrideWithValue(_carteController),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: SvgPicture.asset(
                  'assets/Logo.svg',
                ),
              ),
              const SizedBox(width: 4),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Route',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'MuseoModerno',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    TextSpan(
                      text: 'Pulse',
                      style: TextStyle(
                        color: AppColors.coral,
                        fontFamily: 'MuseoModerno',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.coral.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  user?.initiales ?? '?',
                  style: const TextStyle(
                    color: AppColors.coral,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: IndexedStack(
          index: currentIndex,
          children: [
            const DashboardView(onVoirTout: null),
            const LivraisonsListView(),
            const CarteView(),
            const StatsView(),
            const GestionView(),
          ],
        ),
        bottomNavigationBar: _AppNavBar(
          currentIndex: currentIndex,
          onTap: _navigateTo,
        ),
      ),
    );
  }
}

class _AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AppNavBar({required this.currentIndex, required this.onTap});

  static const _icons = [
    Icons.home_rounded,
    Icons.local_shipping_rounded,
    Icons.location_on_rounded,
    Icons.bar_chart_rounded,
    Icons.assignment_outlined,
  ];

  static const _labels = [
    'Accueil',
    'Livraisons',
    'Carte',
    'Stats',
    'Gestion',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.bgPrincipal,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: List.generate(_icons.length, (i) => _NavItem(
          icon: _icons[i],
          label: _labels[i],
          isActive: i == currentIndex,
          isLeftAdjacent: i == currentIndex - 1,
          isRightAdjacent: i == currentIndex + 1,
          onTap: () => onTap(i),
        )),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isLeftAdjacent;
  final bool isRightAdjacent;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isLeftAdjacent,
    required this.isRightAdjacent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive)
              _ActiveNavIcon(icon: icon, label: label)
            else
              _InactiveNavIcon(
                icon: icon,
                label: label,
                isLeftAdjacent: isLeftAdjacent,
                isRightAdjacent: isRightAdjacent,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveNavIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActiveNavIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.coral,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withOpacity(0.40),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _InactiveNavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLeftAdjacent;
  final bool isRightAdjacent;

  const _InactiveNavIcon({
    required this.icon,
    required this.label,
    required this.isLeftAdjacent,
    required this.isRightAdjacent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 75,
      decoration: BoxDecoration(
        color: AppColors.bgPrincipal,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(isLeftAdjacent ? 16 : 0),
          topLeft: Radius.circular(isRightAdjacent ? 16 : 0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.coral, size: 22),
        ],
      ),
    );
  }
}