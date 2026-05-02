import 'package:flutter/material.dart';

/// Logo GRH-MOBILE — asset PNG couleur (teal + orange).
/// Le logo est affiché tel quel sans filtre de couleur.
class GrhLogo extends StatelessWidget {
  const GrhLogo({
    super.key,
    this.iconSize = 42,
    this.textScale = 1,
    this.stacked = false,
    this.cover = true,
    bool darkBackground = false,
    bool light = false,
  }) : darkBackground = darkBackground || light;

  final double iconSize;
  final double textScale;
  final bool stacked;
  final bool cover;
  final bool darkBackground;

  static const String _assetPath = 'assets/images/grh_logo.png';

  @override
  Widget build(BuildContext context) {
    final height = iconSize * 1.8 * textScale;
    final width  = height * 1.6;

    final logoImage = SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        _assetPath,
        fit: cover ? BoxFit.contain : BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );

    if (!stacked) return logoImage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoImage,
        const SizedBox(height: 8),
        Text(
          'Gestion RH SaaS pour PME togolaises',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.72),
              ),
        ),
      ],
    );
  }
}
