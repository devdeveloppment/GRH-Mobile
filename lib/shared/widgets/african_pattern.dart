import 'package:flutter/material.dart';
import 'package:grh_mobile/core/constants/app_colors.dart';

class AfricanPattern extends StatelessWidget {
  const AfricanPattern({
    super.key,
    required this.child,
    this.opacity = 0.04,
  });

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AfricanPatternPainter(opacity),
      child: child,
    );
  }
}

class _AfricanPatternPainter extends CustomPainter {
  const _AfricanPatternPainter(this.opacity);

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    const spacing = 54.0;
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        final path = Path()
          ..moveTo(x + spacing / 2, y)
          ..lineTo(x + spacing, y + spacing / 2)
          ..lineTo(x + spacing / 2, y + spacing)
          ..lineTo(x, y + spacing / 2)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AfricanPatternPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
