import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Hard offset shadow for the "sticker" look.
const double _stickerShadowOffset = 3.2;

/// Bordered card with the hard offset shadow ("sticker" look) from the wireframe.
///
/// When tappable, the card sinks down on press (shadow collapses) for the same
/// tactile "stamp" feel as the option cards, plus a light haptic.
class StickerCard extends StatefulWidget {
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
  State<StickerCard> createState() => _StickerCardState();
}

class _StickerCardState extends State<StickerCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final pressed = enabled && _pressed;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOut,
      // sink the card by the shadow's height when pressed
      transform: Matrix4.translationValues(
        0,
        pressed ? _stickerShadowOffset : 0,
        0,
      ),
      decoration: BoxDecoration(
        color: widget.background,
        border: Border.all(color: widget.border, width: widget.borderWidth),
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: [
          BoxShadow(
            color: widget.shadow ?? widget.border,
            // shadow collapses as the card sinks into it
            offset: Offset(0, pressed ? 0 : _stickerShadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      padding: widget.padding,
      child: widget.child,
    );
    if (!enabled) return card;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap!.call();
      },
      child: card,
    );
  }
}
