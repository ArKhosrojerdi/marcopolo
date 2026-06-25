import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wordle-style blank cells showing typed characters.
/// [length] = total cells (correct answer length).
/// [typed] = characters typed so far.
/// [state] = null (unanswered), true (correct), false (wrong).
/// [revealAnswer] shown below cells when wrong.
class WordBlanks extends StatefulWidget {
  const WordBlanks({
    super.key,
    required this.length,
    required this.typed,
    this.state,
    this.revealAnswer,
  });

  final int length;
  final String typed;
  final bool? state;
  final String? revealAnswer;

  @override
  State<WordBlanks> createState() => _WordBlanksState();
}

class _WordBlanksState extends State<WordBlanks> with TickerProviderStateMixin {
  // Per-cell: letter scale-in on type
  late List<AnimationController> _typeCtrl;
  late List<Animation<double>> _typeScale;

  // Per-cell: pop (correct) or shake (wrong) on answer
  late List<AnimationController> _resultCtrl;
  late List<Animation<double>> _resultPop;
  late List<Animation<double>> _resultShake;

  static const _staggerMs = 60;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.length);
  }

  void _initControllers(int length) {
    _typeCtrl = List.generate(
      length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 220)),
    );
    _typeScale = _typeCtrl.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 60),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeOut)),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 20,
        ),
      ]).animate(c);
    }).toList();

    _resultCtrl = List.generate(
      length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 380)),
    );
    _resultPop = _resultCtrl.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 40),
        TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
          weight: 60,
        ),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();
    _resultShake = _resultCtrl.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 7.0, end: -5.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -5.0, end: 3.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 1),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();
  }

  void _fireResult(bool correct) {
    for (int i = 0; i < _resultCtrl.length; i++) {
      Future.delayed(Duration(milliseconds: i * _staggerMs), () {
        if (!mounted) return;
        _resultCtrl[i].forward(from: 0.0);
      });
    }
  }

  @override
  void didUpdateWidget(WordBlanks old) {
    super.didUpdateWidget(old);

    if (widget.length != old.length) {
      for (final c in _typeCtrl) { c.dispose(); }
      for (final c in _resultCtrl) { c.dispose(); }
      _initControllers(widget.length);
      return;
    }

    // Letter typed: scale-in the new cell.
    final newLen = widget.typed.length;
    final oldLen = old.typed.length;
    if (newLen > oldLen && newLen - 1 < _typeCtrl.length) {
      _typeCtrl[newLen - 1].forward(from: 0.0);
    }

    // Answer submitted: fire staggered result animation.
    if (widget.state != null && old.state == null) {
      _fireResult(widget.state!);
    }
  }

  @override
  void dispose() {
    for (final c in _typeCtrl) { c.dispose(); }
    for (final c in _resultCtrl) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color cellBorder(int i) {
      if (widget.state == null) {
        return i < widget.typed.length ? AppColors.ink : AppColors.dimBorder;
      }
      return widget.state! ? AppColors.correct : AppColors.wrong;
    }

    Color cellBg(int i) {
      if (widget.state == null) return AppColors.card;
      return widget.state! ? AppColors.correctBg : AppColors.wrongBg;
    }

    final cells = List.generate(widget.length, (i) {
      final char = i < widget.typed.length ? widget.typed[i] : '';
      final correct = widget.state == true;
      final wrong = widget.state == false;

      return AnimatedBuilder(
        animation: Listenable.merge([_typeCtrl[i], _resultCtrl[i]]),
        builder: (context, child) {
          final scale = correct ? _resultPop[i].value : 1.0;
          final dx = wrong ? _resultShake[i].value : 0.0;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cellBg(i),
            border: Border.all(color: cellBorder(i), width: 1.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ScaleTransition(
            scale: _typeScale[i],
            child: Text(
              char,
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
                height: 1,
              ),
            ),
          ),
        ),
      );
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: cells,
        ),
        if (widget.state == false && widget.revealAnswer != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.revealAnswer!,
            style: const TextStyle(
              fontFamily: AppTheme.sans,
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}
