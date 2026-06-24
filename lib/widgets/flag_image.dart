import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Renders a country flag SVG inside a dark 2px frame, with margin around it.
class FlagImage extends StatelessWidget {
  const FlagImage({super.key, required this.assetPath, this.height = 200});

  final String assetPath;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: SvgPicture.asset(
          assetPath,
          height: height,
          fit: BoxFit.contain,
          placeholderBuilder: (_) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}
