import 'package:flutter/material.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';
import 'package:grh_mobile/shared/models/dashboard_models.dart';
import 'package:grh_mobile/shared/widgets/employee_avatar.dart';

class LeaveRequestCard extends StatelessWidget {
  final LeaveRequest leave;

  const LeaveRequestCard({required this.leave, super.key});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROUVE':
        return Colors.green.shade500;
      case 'EN_ATTENTE':
        return AppColors.accent;
      case 'REJETE':
        return Colors.red.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'APPROUVE':
        return 'Approuvé';
      case 'EN_ATTENTE':
        return 'En attente';
      case 'REJETE':
        return 'Rejeté';
      default:
        return status;
    }
  }

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
            name: leave.employeeName,
            imageUrl: leave.avatarUrl,
            size: 48,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leave.employeeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Congé annuel : ${leave.startDate.day}/${leave.startDate.month} - ${leave.endDate.day}/${leave.endDate.month}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            decoration: BoxDecoration(
              color: _getStatusColor(leave.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              _getStatusLabel(leave.status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(leave.status),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
