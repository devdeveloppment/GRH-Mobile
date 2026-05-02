import 'package:flutter/material.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/shared/models/dashboard_models.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';

class BirthdayCard extends StatelessWidget {
  final Birthday birthday;

  const BirthdayCard({required this.birthday, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          EmployeeAvatar(
            name: birthday.employeeName,
            imageUrl: birthday.avatarUrl,
            size: 48,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  birthday.employeeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${birthday.birthDate.day}/${birthday.birthDate.month}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Gift icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.card_giftcard, color: Colors.orange.shade600, size: 22),
          ),
        ],
      ),
    );
  }
}
