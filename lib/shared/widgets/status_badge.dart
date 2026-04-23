import 'package:flutter/material.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  final String label;
  final String type;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (type) {
      'success' => AppColors.success,
      'warning' => AppColors.warning,
      'error' => AppColors.danger,
      'info' => AppColors.info,
      _ => AppColors.neutral,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
