import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Couleur primaire : bleu marine sécurité
  static const Color primary = Color(0xFF1B3A6B);
  static const Color primaryLight = Color(0xFF2A5298);
  static const Color primaryDark = Color(0xFF0F2244);

  // Accent : teal connectivité
  static const Color accent = Color(0xFF00C4B4);
  static const Color accentLight = Color(0xFF33D1C3);
  static const Color accentDark = Color(0xFF009E90);

  // Danger / Kill Switch : rouge vif
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFB91C1C);

  // Avertissement : orange
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);

  // Succès
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);

  // Fond et texte
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A2035);
  static const Color text = Color(0xFF1A202C);
  static const Color textLight = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF718096);

  // Fond sombre
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color backgroundDarkSurface = Color(0xFF1E293B);

  // En ligne / hors ligne
  static const Color online = Color(0xFF10B981);
  static const Color offline = Color(0xFF9CA3AF);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.danger,
        background: AppColors.background,
        surface: AppColors.surface,
        onBackground: AppColors.text,
        onSurface: AppColors.text,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.text,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textLight,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textLight),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.all(
          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary.withOpacity(0.1),
        labelStyle: GoogleFonts.inter(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: AppColors.backgroundDark,
        secondary: AppColors.primaryLight,
        onSecondary: Colors.white,
        error: AppColors.dangerLight,
        background: AppColors.backgroundDark,
        surface: AppColors.backgroundDarkSurface,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDarkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
