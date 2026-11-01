import 'package:flutter/material.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isLoading = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? trend;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        // Bordure uniforme : Flutter refuse un borderRadius avec des couleurs de bordure différentes.
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Label + trend ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.text2,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: 4),
                Icon(
                  trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: trend! >= 0 ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 2),
                Text(
                  '${trend!.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trend! >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // ── Valeur ──────────────────────────────────────────────────
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text1,
            ),
          ),
        ],
      ),
    );

    if (!isLoading) return content;

    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: Colors.white.withOpacity(0.6),
      child: content,
    );
  }
}
