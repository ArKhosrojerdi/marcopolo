import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a country border-outline map SVG (square, filled with the theme
/// green). No frame — the silhouette sits on the paper background.
class MapImage extends StatelessWidget {
  const MapImage({super.key, required this.assetPath, this.size = 200});

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Shrink the map on shorter screens so it fits alongside the keyboard.
    // 840 ≈ reference height; matches FlagImage / WordBlanks scaling.
    final screenH = MediaQuery.sizeOf(context).height;
    final heightScale = (screenH / 840).clamp(0.6, 1.0);
    final scaled = size * heightScale;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SvgPicture.asset(
          assetPath,
          height: scaled,
          width: scaled,
          fit: BoxFit.contain,
          placeholderBuilder: (_) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}
