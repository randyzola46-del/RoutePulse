// lib/views/onboarding_view.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

const String _kOnboardingDone = 'onboarding_completed';

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

// ─── Données des slides ───────────────────────────────────────────────────────

class _OnboardingSlide {
  final String title;
  final String subtitle;
  final String description;
  final Color accentColor;
  final List<Color> gradientColors;
  final String backgroundImage;

  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accentColor,
    required this.gradientColors,
    required this.backgroundImage,
  });
}

const _slides = [
  _OnboardingSlide(
    title: 'RoutePulse',
    subtitle: 'Vos livraisons,\nsous contrôle.',
    description: 'Gérez, suivez et optimisez chaque livraison.',
    accentColor: AppColors.coral,
    gradientColors: [Color(0xFFEA7C69), Color(0xFFFF9A85)],
    backgroundImage: 'assets/onboarding/livraison.jpg',
  ),
  _OnboardingSlide(
    title: 'RoutePulse',
    subtitle: 'Itinéraires\nintelligents',
    description: 'Le chemin le plus court pour vos livraisons.',
    accentColor: AppColors.statusLivree,
    gradientColors: [Color(0xFF50D1AA), Color(0xFF6FECBF)],
    backgroundImage: 'assets/onboarding/route_map_bg.jpg',
  ),
  _OnboardingSlide(
    title: 'RoutePulse',
    subtitle: 'Suivi en\ntemps réel',
    description: 'Chaque colis, chaque client, en direct.',
    accentColor: AppColors.statusAttente,
    gradientColors: [Color(0xFF9288E0), Color(0xFFADA3F5)],
    backgroundImage: 'assets/onboarding/truck_delivery_bg.jpg',
  ),
];

// ─── Widget principal ─────────────────────────────────────────────────────────

class OnboardingView extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingView({super.key, required this.onDone});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrincipal,
      body: Stack(
        children: [
          // Fond avec image et dégradé
          _AnimatedBackground(
            color: _slides[_currentPage].accentColor,
            pageIndex: _currentPage,
            backgroundImage: _slides[_currentPage].backgroundImage,
          ),
          // Contenu
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // Skip button
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 20),
                      child: _currentPage < _slides.length - 1
                          ? TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Passer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                          : const SizedBox(height: 40),
                    ),
                  ),
                ),

                const Spacer(flex: 5),

                // Slides
                Expanded(
                  flex: 5,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (i) {
                      setState(() => _currentPage = i);
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                    itemBuilder: (_, i) => _SlideContent(
                      slide: _slides[i],
                    ),
                  ),
                ),

                // Bottom: dots + bouton
                _BottomBar(
                  currentPage: _currentPage,
                  totalPages: _slides.length,
                  accentColor: _slides[_currentPage].accentColor,
                  gradientColors: _slides[_currentPage].gradientColors,
                  onNext: _goToNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide content ────────────────────────────────────────────────────────────

class _SlideContent extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideContent({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: slide.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: slide.accentColor.withOpacity(0.2), width: 1),
            ),
            child: Text(
              slide.title.toUpperCase(),
              style: TextStyle(
                color: slide.accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Titre principal - Aligné à gauche
          Text(
            slide.subtitle,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 20),

          // Description - Alignée à gauche
          Text(
            slide.description,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color accentColor;
  final List<Color> gradientColors;
  final VoidCallback onNext;

  const _BottomBar({
    required this.currentPage,
    required this.totalPages,
    required this.accentColor,
    required this.gradientColors,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == totalPages - 1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Dots
            Row(
              children: List.generate(totalPages, (i) {
                final isActive = i == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  margin: const EdgeInsets.only(right: 6),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? accentColor
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            // Bouton
            GestureDetector(
              onTap: onNext,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                height: 54,
                width: isLast ? 200 : 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(27),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLast) ...[
                      const Text(
                        'Commencer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fond animé avec image et dégradé ─────────────────────────────────────────

class _AnimatedBackground extends StatefulWidget {
  final Color color;
  final int pageIndex;
  final String backgroundImage;

  const _AnimatedBackground({
    required this.color,
    required this.pageIndex,
    required this.backgroundImage,
  });

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotController;

  @override
  void initState() {
    super.initState();
    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppColors.bgPrincipal,
        image: DecorationImage(
          image: AssetImage(widget.backgroundImage),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            widget.color.withOpacity(0.15),
            BlendMode.softLight,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              widget.color.withOpacity(0.25),
              AppColors.bgPrincipal.withOpacity(0.9),
              AppColors.bgPrincipal,
            ],
            stops: const [0.0, 0.15, 0.35, 0.6, 1.0],
          ),
        ),
        child: AnimatedBuilder(
          animation: _rotController,
          builder: (_, __) => CustomPaint(
            painter: _BgPainter(
              color: widget.color,
              rotation: _rotController.value * 2 * math.pi,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  final Color color;
  final double rotation;

  _BgPainter({required this.color, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Grand cercle en haut à droite - opacité réduite
    paint.color = color.withOpacity(0.04);
    canvas.save();
    canvas.translate(size.width * 0.85, size.height * 0.12);
    canvas.rotate(rotation * 0.3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 320, height: 280),
      paint,
    );
    canvas.restore();

    // Cercle moyen en bas à gauche - opacité réduite
    paint.color = color.withOpacity(0.03);
    canvas.save();
    canvas.translate(size.width * 0.1, size.height * 0.82);
    canvas.rotate(-rotation * 0.5);
    canvas.drawCircle(Offset.zero, 180, paint);
    canvas.restore();

    // Petit accent - opacité réduite
    paint.color = color.withOpacity(0.05);
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.55);
    canvas.rotate(rotation);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 100, height: 60),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BgPainter old) =>
      old.color != color || old.rotation != rotation;
}