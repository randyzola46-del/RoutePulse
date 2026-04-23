// lib/widgets/dashboard_carousel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import '../theme/app_theme.dart';
import '../providers/navigation_provider.dart';

class DashboardCarousel extends ConsumerStatefulWidget {
  const DashboardCarousel({super.key});

  @override
  ConsumerState<DashboardCarousel> createState() => _DashboardCarouselState();
}

class _DashboardCarouselState extends ConsumerState<DashboardCarousel> {
  int _currentIndex = 0;
  final cs.CarouselSliderController _controller = cs.CarouselSliderController();
  Timer? _autoPlayTimer;

  String splitTitle(String text) {
    final words = text.split(' ');
    if (words.length <= 2) return text;
    return words.take(2).join(' ') + '\n' + words.skip(2).join(' ');
  }

  final List<CarouselItem> _items = const [
    CarouselItem(
      title: 'Commencer votre tournée',
      actionText: 'Voir les livraisons',
      svgAsset: 'assets/livraison.svg',
      color: Color(0xFF1F9D7A),
      svgWidth: 100,
      svgHeight: 100,
      svgOffsetX: 0,
      svgOffsetY: 0,
      navigationTab: 1, // Index de l'onglet Livraisons
    ),
    CarouselItem(
      title: 'Optimisez vos livraisons',
      actionText: 'Voir la carte',
      svgAsset: 'assets/map.svg',
      color: Color(0xFFD94C75),
      svgWidth: 130,
      svgHeight: 130,
      svgOffsetX: -10,
      svgOffsetY: 0,
      navigationTab: 2, // Index de l'onglet Carte
    ),
    CarouselItem(
      title: 'Analysez vos performances',
      actionText: 'Voir statistique',
      svgAsset: 'assets/stats.svg',
      color: Color(0xFF3E7CB1),
      svgWidth: 120,
      svgHeight: 120,
      svgOffsetX: -10,
      svgOffsetY: 0,
      navigationTab: 3, // Index de l'onglet Stats
    ),
    CarouselItem(
      title: 'Gérez vos véhicules & clients',
      actionText: 'Organiser',
      svgAsset: 'assets/logistic.svg',
      color: Color(0xFFCC8A3E),
      svgWidth: 130,
      svgHeight: 130,
      svgOffsetX: -40,
      svgOffsetY: 0,
      navigationTab: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _onActionTap(int index) {
    final item = _items[index];

    // Utiliser le NavigationProvider pour changer d'onglet
    ref.read(navigationProvider.notifier).setTab(item.navigationTab);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.navigation, size: 18, color: AppColors.statusLivree),
            const SizedBox(width: 8),
            Text('Navigation vers ${_getTabName(item.navigationTab)}'),
          ],
        ),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.coral.withOpacity(0.3)),
        ),
      ),
    );
  }

  String _getTabName(int tabIndex) {
    switch (tabIndex) {
      case 0: return 'Accueil';
      case 1: return 'Livraisons';
      case 2: return 'Carte';
      case 3: return 'Stats';
      case 4: return 'Gestion';
      default: return 'Accueil';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        cs.CarouselSlider(
          items: _buildCarouselItems(),
          carouselController: _controller,
          options: cs.CarouselOptions(
            height: 170,
            viewportFraction: 0.85,
            enlargeCenterPage: true,
            enlargeFactor: 0.25,
            autoPlay: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildDotIndicators(),
      ],
    );
  }

  List<Widget> _buildCarouselItems() {
    return List.generate(_items.length, (index) {
      final item = _items[index];
      final isCenter = _currentIndex == index;

      return SizedBox(
        width: double.infinity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isCenter
                ? [
              BoxShadow(
                color: item.color.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // SVG en arrière-plan
                Positioned(
                  right: item.svgOffsetX ?? -20,
                  bottom: item.svgOffsetY ?? -20,
                  child: Transform.rotate(
                    angle: (item.svgRotation ?? 0) * 3.14159 / 180,
                    child: Opacity(
                      opacity: item.svgOpacity ?? 1,
                      child: SvgPicture.asset(
                        item.svgAsset,
                        width: item.svgWidth ?? 100,
                        height: item.svgHeight ?? 100,
                      ),
                    ),
                  ),
                ),
                // Contenu
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          splitTitle(item.title),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Nunito',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          onTap: () => _onActionTap(index),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.actionText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.navigate_next,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_items.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == index ? 24 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: _currentIndex == index
                ? AppColors.coral
                : AppColors.textMuted.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}

class CarouselItem {
  final String title;
  final String actionText;
  final String svgAsset;
  final Color color;
  final double? svgWidth;
  final double? svgHeight;
  final double? svgOpacity;
  final double? svgOffsetX;
  final double? svgOffsetY;
  final double? svgRotation;
  final int navigationTab;

  const CarouselItem({
    required this.title,
    required this.actionText,
    required this.svgAsset,
    required this.color,
    this.svgWidth,
    this.svgHeight,
    this.svgOpacity,
    this.svgOffsetX,
    this.svgOffsetY,
    this.svgRotation,
    required this.navigationTab,
  });
}