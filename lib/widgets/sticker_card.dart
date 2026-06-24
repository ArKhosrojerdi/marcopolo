import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bordered card with the hard offset shadow ("sticker" look) from the wireframe.
class StickerCard extends StatelessWidget {
  const StickerCard({
    super.key,
    required this.child,
    this.background = AppColors.card,
    this.border = AppColors.ink,
    this.borderWidth = 1.6,
    this.radius = 6,
    this.shadow,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });

  final Widget child;
  final Color background;
  final Color border;
  final double borderWidth;
  final double radius;
  final Color? shadow;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: AppTheme.sticker(
        background: background,
        border: border,
        borderWidth: borderWidth,
        radius: radius,
        shadow: shadow,
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: card,
    );
  }
}
