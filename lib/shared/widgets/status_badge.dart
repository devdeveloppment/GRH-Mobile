import 'package:flutter/material.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  final String label;
  // Valeurs reconnues : 'active' | 'leave' | 'rejected' | 'pending'
  // Alias legacy      : 'success' | 'warning' | 'error' | 'info'
  final String type;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      'active'  || 'success' => (AppColors.badgeSuccessBg, AppColors.badgeSuccessFg),
      'leave'   || 'warning' || 'pending' || 'info'
                             => (AppColors.badgeWarnBg,    AppColors.badgeWarnFg),
      'rejected'|| 'error'   => (AppColors.badgeDangerBg,  AppColors.badgeDangerFg),
      _                      => (AppColors.surface,         AppColors.text2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
