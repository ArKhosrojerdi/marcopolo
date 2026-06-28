import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/seasons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/press_sink.dart';
import '../quiz/panel.dart';

/// Result screen for a finished level: star rating (lives left), score, and an
/// exit back to the level grid. Passing (≥1 life) vs failing (0 lives) changes
/// the headline; either way the next level is already unlocked by the time we
/// get here (the level was played).
class LevelComplete extends StatelessWidget {
  const LevelComplete({
    super.key,
    required this.level,
    required this.stars,
    required this.correct,
    required this.total,
    required this.passed,
    required this.onExit,
    this.onNext,
    this.onRetry,
  });

  final LevelDef level;
  final int stars;
  final int correct;
  final int total;
  final bool passed;
  final VoidCallback onExit;

  /// Advance to the next level. Non-null only on a pass with a next level.
  final VoidCallback? onNext;

  /// Replay this level. Non-null only on a fail.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            passed ? 'آفرین!' : 'تمام شد',
            textAlign: TextAlign.center,
            style: AppTheme.handSize(40),
          ),
          const SizedBox(height: 18),
          _StarRow(stars: stars),
          const SizedBox(height: 18),
          Panel(
            children: [
              Text(
                '${toPersianDigits(correct)} از ${toPersianDigits(total)} درست',
                style: AppTheme.handSize(28, color: AppColors.correct),
              ),
              const SizedBox(height: 8),
              Text(
                passed ? 'مرحله بعدی باز شد' : 'دوباره تلاش کن',
                style: const TextStyle(
                  fontFamily: AppTheme.sans,
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Primary action: next level on a pass, retry on a fail. Sits on top
          // of the always-present "back to levels" button.
          if (onNext != null) ...[
            _CompleteButton(
              label: 'مرحله بعدی ›',
              primary: true,
              onTap: onNext!,
            ),
            const SizedBox(height: 12),
          ] else if (onRetry != null) ...[
            _CompleteButton(
              label: 'تلاش دوباره',
              primary: true,
              onTap: onRetry!,
            ),
            const SizedBox(height: 12),
          ],
          _CompleteButton(
            label: 'بازگشت به مراحل',
            primary: onNext == null && onRetry == null,
            onTap: onExit,
          ),
        ],
      ),
    );
  }
}

/// Full-width sticker button. [primary] fills with ink; otherwise outline.
class _CompleteButton extends StatelessWidget {
  const _CompleteButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressSink(
      onTap: onTap,
      borderRadius: 24,
      background: primary ? AppColors.ink : AppColors.card,
      borderWidth: 1.6,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.sans,
          fontSize: 15,
          color: primary ? AppColors.card : AppColors.ink,
        ),
      ),
    );
  }
}

/// Three stars; earned ones slam in one-by-one with an overshoot pop, a wobble,
/// and a burst flash. Hollow stars just fade in quietly behind them.
class _StarRow extends StatefulWidget {
  const _StarRow({required this.stars});
  final int stars;

  @override
  State<_StarRow> createState() => _StarRowState();
}

class _StarRowState extends State<_StarRow> with TickerProviderStateMixin {
  // One driver per star slot. Earned stars play the full brutal slam; hollow
  // ones reuse the same controller for a soft fade.
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 620),
        vsync: this,
      ),
    );
    _kickOff();
  }

  Future<void> _kickOff() async {
    // Tiny lead-in so the row is on screen before the first star lands.
    await Future<void>.delayed(const Duration(milliseconds: 180));
    for (var i = 0; i < 3; i++) {
      if (!mounted) return;
      _controllers[i].forward();
      // Stagger: earned stars get a punchy beat between hits; if this slot is
      // earned, wait long enough to feel the slam land.
      final earned = i < widget.stars;
      await Future<void>.delayed(
        Duration(milliseconds: earned ? 240 : 90),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _AnimatedStar(
              controller: _controllers[i],
              earned: i < widget.stars,
            ),
          ),
      ],
    );
  }
}

class _AnimatedStar extends StatelessWidget {
  const _AnimatedStar({required this.controller, required this.earned});

  final AnimationController controller;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    if (!earned) {
      // Hollow slot: filled star drained of color (desaturate + dim) so the
      // gap reads clearly without changing the glyph. Quiet fade-in.
      final fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);
      return FadeTransition(
        opacity: fade,
        child: Opacity(
          opacity: 0.45,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0, //
              0.2126, 0.7152, 0.0722, 0, 0, //
              0.2126, 0.7152, 0.0722, 0, 0, //
              0, 0, 0, 1, 0, //
            ]),
            child: const Text('⭐', style: TextStyle(fontSize: 44)),
          ),
        ),
      );
    }

    // Brutal slam: oversized overshoot down to rest, a quick angular wobble,
    // and a radial flash that blooms out as the star settles.
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 2.4, end: 0.78)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.78, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 26,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 36,
      ),
    ]).animate(controller);

    final wobble = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 38),
      TweenSequenceItem(
        tween: Tween(begin: -0.22, end: 0.16),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.16, end: 0.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 48,
      ),
    ]).animate(controller);

    // Flash blooms right when the star bottoms out, then fades.
    final flash = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
    ]).animate(controller);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Burst flash behind the star.
            Opacity(
              opacity: flash.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1.0 + (1.0 - flash.value) * 1.6,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.postitBorder.withValues(alpha: 0.9),
                        AppColors.postitBorder.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Transform.rotate(
              angle: wobble.value * math.pi,
              child: Transform.scale(
                scale: scale.value.clamp(0.0, 3.0),
                child: child,
              ),
            ),
          ],
        );
      },
      child: Text(
        '⭐',
        style: TextStyle(
          fontSize: 44,
          color: AppColors.postitBorder,
          shadows: [
            Shadow(
              color: AppColors.postitBorder.withValues(alpha: 0.7),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}
