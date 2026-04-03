import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'dashboard_view.dart';
import 'livraisons_list_view.dart';

//Scaffold racine de l'application avec navigation par onglets.
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  void _navigateTo(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardView(onVoirTout: () => _navigateTo(1)),
          const LivraisonsListView(),
          const _PlaceholderPage('Carte'),
          const _PlaceholderPage('Stats'),
          const _PlaceholderPage('Profil'),
        ],
      ),
      bottomNavigationBar: _AppNavBar(
        currentIndex: _currentIndex,
        onTap: _navigateTo,
      ),
    );
  }
}

//Widgets privés

/// Barre de navigation principale de l'application.
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: List.generate(_icons.length, (i) => _NavItem(
          icon: _icons[i],
          isActive: i == currentIndex,
          isLeftAdjacent:  i == currentIndex - 1,
          isRightAdjacent: i == currentIndex + 1,
          onTap: () => onTap(i),
        )),
      ),
    );
  }
}

// Item individuel de la barre de navigation.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isLeftAdjacent;
  final bool isRightAdjacent;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
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
              _ActiveNavIcon(icon: icon)
            else
              _InactiveNavIcon(
                icon: icon,
                isLeftAdjacent: isLeftAdjacent,
                isRightAdjacent: isRightAdjacent,
              ),
          ],
        ),
      ),
    );
  }
}

// Icône active : carré coral surélevé.
class _ActiveNavIcon extends StatelessWidget {
  final IconData icon;
  const _ActiveNavIcon({required this.icon});

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

//Icône inactive sur fond sombre avec coins arrondis contextuels.
class _InactiveNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isLeftAdjacent;
  final bool isRightAdjacent;

  const _InactiveNavIcon({
    required this.icon,
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
          topRight: Radius.circular(isLeftAdjacent  ? 16 : 0),
          topLeft:  Radius.circular(isRightAdjacent ? 16 : 0),
        ),
      ),
      child: Icon(icon, color: AppColors.coral, size: 22),
    );
  }
}

//Page placeholder pour les onglets non encore implémentés.
class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
