import 'package:flutter/material.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
//
// Source de vérité unique pour toutes les couleurs de l'application.
// Les valeurs correspondent exactement à la charte du Dashboard (Ds).
//
class AppColors {
  AppColors._();

  // ── Fonds ────────────────────────────────────────────────────────────────
  /// Fond global de l'application (le plus sombre) — ex. cards, header.
  static const bgPrincipal = Color(0xFF1F1D2B);

  /// Surface des conteneurs principaux (BottomBar, fiches).
  static const surface = Color(0xFF252836);

  /// Surface secondaire (modals, snackbars).
  static const surface2 = Color(0xFF2D3044);

  // ── Accent principal ─────────────────────────────────────────────────────
  /// Coral — couleur primaire (boutons, active state, Total KPI).
  static const coral = Color(0xFFEA7C69);

  /// Coral clair — hover / texte secondaire.
  static const coralLight = Color(0xFFF0957F);

  /// Tinte coral à 10 % — fond des KPI cards.
  static const coralTint = Color(0x1AEA7C69);

  // ── Statuts livraison ────────────────────────────────────────────────────
  /// En attente — violet.
  static const statusAttente = Color(0xFF9288E0);

  /// En attente tinte 10 %.
  static const statusAttenteTint = Color(0x1A9288E0);

  /// En cours — amber.
  static const statusCours = Color(0xFFFFB572);

  /// En cours tinte 10 %.
  static const statusCoursTint = Color(0x1AFFB572);

  /// Livrée — teal.
  static const statusLivree = Color(0xFF50D1AA);

  /// Livrée tinte 10 %.
  static const statusLivreeTint = Color(0x1A50D1AA);

  /// À reporter — rose/pink.
  static const statusReporter = Color(0xFFFF7CA3);

  /// À reporter tinte 10 %.
  static const statusReporterTint = Color(0x1AFF7CA3);

  /// Annulée — coral (même que primaire, signifie action bloquante).
  static const statusAnnulee = Color(0xFFEA7C69);

  // ── Textes ────────────────────────────────────────────────────────────────
  /// Texte principal — blanc légèrement chaud.
  static const textPrimary = Color(0xFFE0E6E9);

  /// Texte secondaire — gris-bleu clair.
  static const textSub = Color(0xFFE0E6E9);

  /// Texte désactivé / métadonnées.
  static const textMuted = Color(0xFF889898);

  // ── Divers ───────────────────────────────────────────────────────────────
  /// Bordure subtile — coral @ 10 %.
  static const border = Color(0x1AEA7C69);
}

// ─── Thème ────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: AppColors.bgPrincipal,

      // ── Color scheme ──────────────────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary:          AppColors.coral,
        secondary:        AppColors.coralLight,
        surface:          AppColors.surface,
        onPrimary:        Colors.white,
        onSurface:        AppColors.textPrimary,
        onSurfaceVariant: AppColors.textMuted,
      ),

      // ── Text theme ────────────────────────────────────────────────────────
      // Toutes les tailles s'appuient sur la police Nunito.
      // Les Views utilisent Theme.of(context).textTheme — pas de styles inline.
      textTheme: const TextTheme(
        // Grands titres (ex. nom du livreur dans le header)
        headlineLarge:  TextStyle(fontSize: 39, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        headlineMedium: TextStyle(fontSize: 31, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        headlineSmall:  TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Nunito'),

        // Titres de section
        titleLarge:  TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        titleSmall:  TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Nunito'),

        // Corps de texte
        bodyLarge:  TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        bodySmall:  TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.textMuted,   fontFamily: 'Nunito'),

        // Labels (badges, chips)
        labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Nunito'),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted,   fontFamily: 'Nunito'),
        labelSmall:  TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted,   fontFamily: 'Nunito'),
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          fontFamily: 'Nunito',
        ),
      ),

      // ── Champs de saisie ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontFamily: 'Nunito',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.statusAnnulee, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: AppColors.coral,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          fontFamily: 'Nunito',
        ),
      ),

      // ── Boutons ───────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.coralLight,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Nunito',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.coral,
          side: const BorderSide(color: AppColors.coral),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),



      // ── Chips ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Nunito',
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Bottom navigation ─────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.coral,
        unselectedItemColor: AppColors.textMuted,
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface2,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Nunito',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),



      // ── BottomSheet ───────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.coral,
        linearTrackColor: AppColors.border,
      ),
    );
  }
}

// ─── Helper statut ────────────────────────────────────────────────────────────

/// Retourne la couleur associée à un [StatutLivraison].
///
/// Accepte le type [dynamic] pour éviter une dépendance circulaire,
/// mais en pratique toujours appelé avec un [StatutLivraison].
Color statutColor(dynamic statut) {
  switch (statut.toString()) {
    case 'StatutLivraison.enAttente': return AppColors.statusAttente;
    case 'StatutLivraison.enCours':  return AppColors.statusCours;
    case 'StatutLivraison.livree':   return AppColors.statusLivree;
    case 'StatutLivraison.aReporter':return AppColors.statusReporter;
    case 'StatutLivraison.annulee':  return AppColors.statusAnnulee;
    default:                         return AppColors.textMuted;
  }
}

/// Retourne la couleur de tinte (10 %) associée à un [StatutLivraison].
/// Utile pour les fonds de badges et KPI cards.
Color statutTintColor(dynamic statut) {
  switch (statut.toString()) {
    case 'StatutLivraison.enAttente': return AppColors.statusAttenteTint;
    case 'StatutLivraison.enCours':  return AppColors.statusCoursTint;
    case 'StatutLivraison.livree':   return AppColors.statusLivreeTint;
    case 'StatutLivraison.aReporter':return AppColors.statusReporterTint;
    case 'StatutLivraison.annulee':  return AppColors.coralTint;
    default:                         return AppColors.border;
  }
}