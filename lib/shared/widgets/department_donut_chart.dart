import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/shared/models/dashboard_models.dart';

class DepartmentDonutChart extends StatelessWidget {
  final List<ChartPoint> data;
  final String title;

  const DepartmentDonutChart({
    required this.data,
    this.title = 'Répartition par département',
    super.key,
  });

  static const List<Color> colors = [
    Color(0xFF0E3D34), // Dark green
    AppColors.accent,   // Orange
    Color(0xFF3B82F6), // Blue
    Color(0xFFA9A9A9), // Grey
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text1,
            ),
          ),
          const SizedBox(height: 24),
          if (data.isNotEmpty)
            Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: data
                          .asMap()
                          .entries
                          .map((e) {
                            final total = data.fold<double>(
                              0,
                              (sum, item) => sum + item.value,
                            );
                            final percentage = (e.value.value / total) * 100;
                            return PieChartSectionData(
                              value: e.value.value,
                              title: '${percentage.toStringAsFixed(0)}%',
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              color: colors[e.key % colors.length],
                            );
                          })
                          .toList(),
                      centerSpaceRadius: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Legend
                Column(
                  children: data
                      .asMap()
                      .entries
                      .map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[e.key % colors.length],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.text1,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${e.value.value.toInt()}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            )
          else
            const Center(
              child: Text('Aucune donnée disponible'),
            ),
        ],
      ),
    );
  }
}
