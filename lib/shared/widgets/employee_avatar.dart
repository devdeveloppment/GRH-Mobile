import 'package:flutter/material.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';

class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.showStatus = false,
    this.isOnline,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final bool showStatus;
  final bool? isOnline;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    final color = _palette[name.codeUnits.fold<int>(0, (sum, item) => sum + item) % _palette.length];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: color.withOpacity(0.16),
            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null || imageUrl!.isEmpty
                ? Text(
                    initials.isEmpty ? 'GR' : initials,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                  )
                : null,
          ),
          if (showStatus)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.26,
                height: size * 0.26,
                decoration: BoxDecoration(
                  color: (isOnline ?? false) ? AppColors.success : AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const List<Color> _palette = [
  AppColors.primary,
  AppColors.secondary,
  AppColors.info,
  AppColors.warning,
  Color(0xFF7A5AF8),
  Color(0xFF0E9384),
];
