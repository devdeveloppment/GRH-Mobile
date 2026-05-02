import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary    = Color(0xFF0E3D34); // vert foncé — sidebar, headers
  static const Color accent     = Color(0xFFF68A1E); // orange — boutons CTA, nav actif

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF); // fond pages
  static const Color surface    = Color(0xFFF5F6FA); // fond app, cards

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color text1    = Color(0xFF1A1A1A); // texte principal
  static const Color text2    = Color(0xFF6B7280); // texte secondaire
  static const Color textHint = Color(0xFF9CA3AF); // placeholder

  // ── Border ─────────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFf59E0B);

  // ── Sidebar nav item (repos) ────────────────────────────────────────────────
  static const Color sidebarItem = Color(0xFF9FE1CB);

  // ── Badge backgrounds ──────────────────────────────────────────────────────
  static const Color badgeSuccessBg  = Color(0xFFDCFCE7);
  static const Color badgeSuccessFg  = Color(0xFF166534);
  static const Color badgeWarnBg     = Color(0xFFFEF3C7);
  static const Color badgeWarnFg     = Color(0xFF92400E);
  static const Color badgeDangerBg   = Color(0xFFFEF2F2);
  static const Color badgeDangerFg   = Color(0xFF991B1B);

  // ── Misc ───────────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);

  // ── Compatibility aliases (anciens noms → nouvelles constantes) ────────────
  // Ces alias seront retirés au fil des étapes de refacto des écrans.
  static const Color secondary        = accent;
  static const Color danger           = error;
  static const Color primaryDark      = Color(0xFF082B22);
  static const Color primarySoft      = Color(0xFFE8F5F1);
  static const Color secondarySoft    = Color(0xFFFEF0DC);
  static const Color navyLight        = Color(0xFF2D6A61);
  static const Color neutral          = text2;
  static const Color info             = Color(0xFF2F8F83);
  static const Color backgroundLight  = surface;
  static const Color surfaceLight     = background;
  static const Color borderLight      = border;
  static const Color textPrimaryLight = text1;
  static const Color textSecondaryLight = text2;

  // Gradients conservés temporairement pour la compatibilité de compilation.
  // AUCUN écran ne doit les utiliser après refacto — remplacer par couleurs unies.
  static const LinearGradient shellGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F6FA)],
  );
  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF0E3D34), Color(0xFF0E3D34)],
  );
  static const LinearGradient authGradient = LinearGradient(
    colors: [Color(0xFF0E3D34), Color(0xFF0E3D34)],
  );
}
