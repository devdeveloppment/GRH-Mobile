import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => _build();

  static ThemeData _build() {
    final ColorScheme cs = ColorScheme.light(
      primary:          AppColors.primary,
      onPrimary:        AppColors.white,
      secondary:        AppColors.accent,
      onSecondary:      AppColors.white,
      error:            AppColors.error,
      onError:          AppColors.white,
      surface:          AppColors.background,
      onSurface:        AppColors.text1,
      surfaceContainerHighest: AppColors.surface,
      outline:          AppColors.border,
      outlineVariant:   AppColors.border,
      surfaceTint:      Colors.transparent,
    );

    final TextTheme txt = GoogleFonts.interTextTheme().copyWith(
      displayLarge:  GoogleFonts.inter(fontWeight: FontWeight.w800),
      displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w800),
      displaySmall:  GoogleFonts.inter(fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
      headlineMedium:GoogleFonts.inter(fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w700),
      titleLarge:    GoogleFonts.inter(fontWeight: FontWeight.w700),
      titleMedium:   GoogleFonts.inter(fontWeight: FontWeight.w600),
      titleSmall:    GoogleFonts.inter(fontWeight: FontWeight.w600),
      bodyLarge:     GoogleFonts.inter(fontWeight: FontWeight.w500),
      bodyMedium:    GoogleFonts.inter(fontWeight: FontWeight.w400),
      bodySmall:     GoogleFonts.inter(fontWeight: FontWeight.w400),
      labelLarge:    GoogleFonts.inter(fontWeight: FontWeight.w700),
      labelMedium:   GoogleFonts.inter(fontWeight: FontWeight.w600),
      labelSmall:    GoogleFonts.inter(fontWeight: FontWeight.w500),
    ).apply(bodyColor: AppColors.text1, displayColor: AppColors.text1);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: txt,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      // ── Cards ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),

      // ── Elevated button (= bouton orange principal) ──────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(44),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),

      // ── Filled button (= bouton primaire vert) ───────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(44),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),

      // ── Outlined button ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),

      // ── Text button ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),

      // ── Input ────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.text2, fontSize: 14),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
        space: 1,
      ),

      // ── Drawer ───────────────────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      // ── Navigation bar (bottom nav mobile) ───────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 9,
            color: active ? AppColors.accent : AppColors.text2,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? AppColors.accent : AppColors.text2,
            size: 22,
          );
        }),
      ),

      // ── Snack bar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentTextStyle: GoogleFonts.inter(color: AppColors.white, fontSize: 13),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.accent.withOpacity(0.12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── DataTable ────────────────────────────────────────────────────────
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(AppColors.surface),
        dividerThickness: 0.5,
        headingTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppColors.text2,
        ),
        dataTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.text1,
        ),
      ),

      // ── Splash / highlight ───────────────────────────────────────────────
      splashColor: AppColors.accent.withOpacity(0.08),
      highlightColor: Colors.transparent,
    );
  }
}
