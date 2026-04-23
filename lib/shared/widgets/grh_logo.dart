import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';

class GrhLogo extends StatelessWidget {
  const GrhLogo({
    super.key,
    this.iconSize = 42,
    this.textScale = 1,
    this.stacked = false,
  });

  final double iconSize;
  final double textScale;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final logoMark = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size.square(iconSize),
          painter: _HexagonLogoPainter(),
        ),
        const SizedBox(width: 12),
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                text: 'GRH',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20 * textScale,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              TextSpan(
                text: '-',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20 * textScale,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              TextSpan(
                text: 'MOBILE',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20 * textScale,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 5, bottom: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!stacked) {
      return logoMark;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoMark,
        const SizedBox(height: 8),
        Text(
          'Gestion RH SaaS pour PME togolaises',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
              ),
        ),
      ],
    );
  }
}

class _HexagonLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();

    for (int index = 0; index < 6; index++) {
      final angle = (60 * index - 30) * 3.1415926535 / 180;
      final x = center.dx + radius * 0.9 * math.cos(angle);
      final y = center.dy + radius * 0.9 * math.sin(angle);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, fillPaint);

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1;

    final glyph = Path()
      ..moveTo(size.width * 0.34, size.height * 0.68)
      ..lineTo(size.width * 0.34, size.height * 0.32)
      ..lineTo(size.width * 0.52, size.height * 0.32)
      ..arcToPoint(
        Offset(size.width * 0.64, size.height * 0.44),
        radius: Radius.circular(size.width * 0.12),
      )
      ..lineTo(size.width * 0.64, size.height * 0.68);

    canvas.drawPath(glyph, linePaint);
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.5),
      Offset(size.width * 0.68, size.height * 0.5),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
