import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF0F4D3F);
  static const Color secondary = Color(0xFFF26422);
  static const Color accent = Color(0xFFF4B400);
  static const Color white = Color(0xFFFFFFFF);

  static const Color navy = Color(0xFF123B5D);
  static const Color navyLight = Color(0xFF2D6A8A);
  static const Color success = Color(0xFF249C73);
  static const Color warning = Color(0xFFF1A208);
  static const Color danger = Color(0xFFD64545);
  static const Color info = Color(0xFF2D7FF9);
  static const Color neutral = Color(0xFF6B7280);

  static const Color backgroundLight = Color(0xFFF6F7F4);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFDDE5E1);
  static const Color textPrimaryLight = Color(0xFF11251F);
  static const Color textSecondaryLight = Color(0xFF5B6B66);

  static const Color backgroundDark = Color(0xFF0C1512);
  static const Color surfaceDark = Color(0xFF14211D);
  static const Color borderDark = Color(0xFF23352E);
  static const Color textPrimaryDark = Color(0xFFF4F8F6);
  static const Color textSecondaryDark = Color(0xFFB5C1BC);

  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A2239), Color(0xFF123B5D), Color(0xFF205375)],
  );

  static LinearGradient cardGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.14),
        color.withOpacity(0.04),
      ],
    );
  }

  static const List<Color> sidebarPattern = [
    Color(0x0AFFFFFF),
    Color(0x0A0F4D3F),
  ];
}
