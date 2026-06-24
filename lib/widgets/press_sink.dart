import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/sound_service.dart';
import '../theme/app_theme.dart';

/// Default sink distance — the card drops by this many px on press while its
/// hard shadow collapses into it. Shared by every "sticker" button.
const double kSinkOffset = 2.0;

/// The shared "sticker stamp" press interaction.
///
/// Tracks a pressed state, fires a light haptic + tap sound on tap, and sinks
/// the [child] down by [sinkOffset] while a hard offset [BoxShadow] (no blur)
/// collapses to zero — the tactile look every button in the app shares.
///
/// The caller supplies the surface look via [background], [border],
/// [borderWidth], and [shape]/[borderRadius]; [PressSink] only owns the press
/// machinery and the shadow. When [onTap] is null the widget is inert (no
/// gesture, no shadow collapse) but still painted, matching the previous
/// per-widget behavior.
class PressSink extends StatefulWidget {
  const PressSink({
    super.key,
    required this.onTap,
    required this.child,
    this.background = AppColors.card,
    this.border = AppColors.ink,
    this.borderWidth = 1.6,
    this.shape = BoxShape.rectangle,
    this.borderRadius = 4,
    this.shadowColor,
    this.sinkOffset = kSinkOffset,
    this.padding,
    this.width,
    this.height,
    this.alignment,
  });

  final VoidCallback? onTap;
  final Widget child;
  final Color background;
  final Color border;
  final double borderWidth;

  /// Rectangle (uses [borderRadius]) or circle.
  final BoxShape shape;
  final double borderRadius;

  /// Shadow color; defaults to [border].
  final Color? shadowColor;

  /// How far the card sinks on press (and the resting shadow offset).
  final double sinkOffset;

  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  @override
  State<PressSink> createState() => _PressSinkState();
}

class _PressSinkState extends State<PressSink> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final pressed = enabled && _pressed;
    final isCircle = widget.shape == BoxShape.circle;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOut,
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      padding: widget.padding,
      // sink the card down by the shadow's height when pressed
      transform: Matrix4.translationValues(0, pressed ? widget.sinkOffset : 0, 0),
      decoration: BoxDecoration(
        color: widget.background,
        border: Border.all(color: widget.border, width: widget.borderWidth),
        shape: widget.shape,
        borderRadius:
            isCircle ? null : BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: widget.shadowColor ?? widget.border,
            // shadow collapses as the card sinks into it
            offset: Offset(0, pressed ? 0 : widget.sinkOffset),
            blurRadius: 0,
          ),
        ],
      ),
      child: widget.child,
    );

    if (!enabled) return card;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        HapticFeedback.lightImpact();
        SoundService.instance.playTap();
        widget.onTap!.call();
      },
      child: card,
    );
  }
}
