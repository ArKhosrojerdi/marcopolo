import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Visual state of an answer option after the user has answered.
enum OptionVisual { idle, correct, wrong, dim }

/// An answer option card with the paper-marking states from the wireframe:
/// idle (dark border + hard shadow), correct (green ✓), wrong (red ✗),
/// dim (faded, for the unrelated options once answered).
///
/// On press the card sinks down (shadow collapses) and fires a light haptic,
/// giving a tactile "stamp" feel.
class OptionButton extends StatefulWidget {
  const OptionButton({
    super.key,
    required this.label,
    required this.visual,
    this.onTap,
  });

  final String label;
  final OptionVisual visual;
  final VoidCallback? onTap;

  @override
  State<OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    late final Color border, textColor, bg, shadow;
    // constant border width across all states so answering doesn't nudge layout
    const double borderWidth = 2;
    Widget? mark;

    switch (widget.visual) {
      case OptionVisual.idle:
        border = AppColors.ink;
        textColor = AppColors.ink;
        bg = AppColors.card;
        shadow = AppColors.ink;
      case OptionVisual.correct:
        border = AppColors.correct;
        textColor = AppColors.ink;
        bg = AppColors.correctBg;
        shadow = AppColors.correct;
        mark = _mark('✓', AppColors.correct);
      case OptionVisual.wrong:
        border = AppColors.wrong;
        textColor = AppColors.ink;
        bg = AppColors.wrongBg;
        shadow = AppColors.wrong;
        mark = _mark('✗', AppColors.wrong);
      case OptionVisual.dim:
        border = AppColors.dimBorder;
        textColor = AppColors.dimText;
        bg = AppColors.card;
        shadow = Colors.transparent;
    }

    final enabled = widget.onTap != null;
    final pressed = enabled && _pressed;
    final hasShadow = shadow != Colors.transparent;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOut,
      // sink the card down by the shadow's height when pressed
      transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: borderWidth),
        borderRadius: BorderRadius.circular(4),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: shadow,
                  // shadow collapses as the card sinks into it
                  offset: Offset(0, pressed ? 0 : 2),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Text(
        widget.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.sans,
          fontSize: 15,
          color: textColor,
        ),
      ),
    );

    // Badge sits in an outer Stack (not clipped by the card's border radius),
    // overlapping the top-left corner above the card.
    final marked = mark == null
        ? card
        : Stack(
            clipBehavior: Clip.none,
            children: [
              card,
              Positioned(left: -8, top: -8, child: mark),
            ],
          );

    if (!enabled) return marked;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap!.call();
      },
      child: marked,
    );
  }

  Widget _mark(String glyph, Color color) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Text(
          glyph,
          style: const TextStyle(
            fontFamily: AppTheme.hand,
            fontSize: 16,
            height: 1,
            color: Colors.white,
          ),
        ),
      );
}
