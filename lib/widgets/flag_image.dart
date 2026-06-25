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
    // Shrink the flag on shorter screens so it fits alongside the keyboard.
    // 840 ≈ reference height; matches WordBlanks' height scaling.
    final screenH = MediaQuery.sizeOf(context).height;
    final heightScale = (screenH / 840).clamp(0.6, 1.0);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: SvgPicture.asset(
          assetPath,
          height: height * heightScale,
          fit: BoxFit.contain,
          placeholderBuilder: (_) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}
