import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'press_sink.dart';

/// Hard offset shadow for the "sticker" look.
const double _stickerShadowOffset = 3.2;

/// Bordered card with the hard offset shadow ("sticker" look) from the wireframe.
///
/// When tappable, the card sinks down on press (shadow collapses) for the same
/// tactile "stamp" feel as the option cards, plus a light haptic — all owned by
/// [PressSink]. When [onTap] is null the card is painted but inert.
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
    return PressSink(
      onTap: onTap,
      background: background,
      border: border,
      borderWidth: borderWidth,
      borderRadius: radius,
      shadowColor: shadow,
      sinkOffset: _stickerShadowOffset,
      padding: padding,
      child: child,
    );
  }
}
