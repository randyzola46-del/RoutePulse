import 'package:flutter/material.dart';

class AppColors {
  // Palette Coral Charcoal
  static const bgPrincipal   = Color(0xFF1C1E27);
  static const surface       = Color(0xFF252830);
  static const surface2      = Color(0xFF2D303C);
  static const coral         = Color(0xFFE8613A);
  static const coralLight    = Color(0xFFF0845F);
  static const textPrimary   = Color(0xFFF0F0F0);
  static const textMuted     = Color(0xFF5A5E72);
  static const border        = Color(0x1AE8613A); // coral @ 10%

  // Statuts
  static const statusAttente  = Color(0xFF607ADB);
  static const statusCours    = Color(0xFFE8613A);
  static const statusLivree   = Color(0xFF10B981);
  static const statusReporter = Color(0xFF5A5E72);
  static const statusAnnulee  = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrincipal,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.coral,
        secondary: AppColors.coralLight,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Nunito',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          fontFamily: 'Nunito',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.coral.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.coral.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: AppColors.coral,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFamily: 'Nunito',
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.coralLight,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.coral.withOpacity(0.08),
        thickness: 0.5,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.coral,
        unselectedItemColor: AppColors.textMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface2,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Helpers couleur par statut
Color statutColor(dynamic statut) {
  switch (statut.toString()) {
    case 'StatutLivraison.enAttente':
      return AppColors.statusAttente;
    case 'StatutLivraison.enCours':
      return AppColors.statusCours;
    case 'StatutLivraison.livree':
      return AppColors.statusLivree;
    case 'StatutLivraison.aReporter':
      return AppColors.statusReporter;
    case 'StatutLivraison.annulee':
      return AppColors.statusAnnulee;
    default:
      return AppColors.textMuted;
  }
}
