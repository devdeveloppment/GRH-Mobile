import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.accent,
      error: AppColors.danger,
      onError: Colors.white,
      surfaceTint: Colors.transparent,
      outline: isDark ? AppColors.borderDark : AppColors.borderLight,
      outlineVariant: isDark ? AppColors.borderDark.withOpacity(0.75) : AppColors.borderLight,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      background: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      onBackground: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );

    final TextTheme baseTextTheme = GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      displayMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      displaySmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      headlineMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      titleSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      bodyLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.dmSans(fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
      labelMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      textTheme: baseTextTheme.apply(
        bodyColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        displayColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.backgroundDark.withOpacity(0.8) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        hintStyle: GoogleFonts.dmSans(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        selectedColor: AppColors.accent.withOpacity(0.16),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        indicatorColor: AppColors.accent.withOpacity(0.18),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      splashColor: AppColors.accent.withOpacity(0.12),
      highlightColor: Colors.transparent,
    );
  }
}
