import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'press_sink.dart';

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
    this.celebrate = false,
    this.onTap,
  });

  final String label;
  final OptionVisual visual;

  /// Whether a `correct` card should pop. False on a wrong answer so the
  /// revealed correct option stays still and only the wrong card animates.
  final bool celebrate;
  final VoidCallback? onTap;

  @override
  State<OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton>
    with TickerProviderStateMixin {
  // Pop for the correct answer (quick scale-up then settle).
  late final AnimationController _popCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final Animation<double> _pop = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 40),
    TweenSequenceItem(
      tween: Tween(begin: 1.08, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 60,
    ),
  ]).animate(_popCtrl);

  // Horizontal shake for the wrong answer.
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _shake = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -6.0, end: 4.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

  void _runForVisual(OptionVisual v) {
    // The correct card always plays its badge reveal; the card-pop scale is
    // gated on `celebrate` (see build) so it only bounces when the player
    // actually picked the right answer.
    if (v == OptionVisual.correct) _popCtrl.forward(from: 0);
    if (v == OptionVisual.wrong) _shakeCtrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(OptionButton old) {
    super.didUpdateWidget(old);
    if (widget.visual != old.visual) _runForVisual(widget.visual);
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
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

    // The press sink (pressed-state, haptic, tap sound, sink + collapsing
    // shadow) is shared via [PressSink]; this widget keeps only the per-visual
    // surface and the pop/shake animations below. Once answered onTap is null,
    // so PressSink renders inert. The dim state has no shadow (transparent).
    final card = PressSink(
      onTap: widget.onTap,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      background: bg,
      border: border,
      borderWidth: borderWidth,
      borderRadius: 4,
      shadowColor: shadow,
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
    // overlapping the top-left corner above the card. It pops in with the card.
    final marked = mark == null
        ? card
        : Stack(
            clipBehavior: Clip.none,
            children: [
              card,
              Positioned(
                left: -8,
                top: -8,
                child: ScaleTransition(
                  scale: widget.visual == OptionVisual.correct
                      ? _pop
                      : CurvedAnimation(
                          parent: _shakeCtrl,
                          curve: Curves.elasticOut,
                        ),
                  child: mark,
                ),
              ),
            ],
          );

    // Correct => pop scale; wrong => horizontal shake.
    final animated = AnimatedBuilder(
      animation: Listenable.merge([_popCtrl, _shakeCtrl]),
      builder: (context, child) {
        final scale =
            widget.visual == OptionVisual.correct && widget.celebrate
                ? _pop.value
                : 1.0;
        final dx = widget.visual == OptionVisual.wrong ? _shake.value : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: marked,
    );

    return animated;
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
