import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a country flag SVG, no frame — just the flag.
class FlagImage extends StatelessWidget {
  const FlagImage({super.key, required this.assetPath, this.height = 200});

  final String assetPath;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        placeholderBuilder: (_) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}
