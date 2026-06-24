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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SvgPicture.asset(
          assetPath,
          height: size,
          width: size,
          fit: BoxFit.contain,
          placeholderBuilder: (_) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}
