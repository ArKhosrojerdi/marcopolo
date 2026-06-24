import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/quiz_repository.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/flag_image.dart';
import '../widgets/map_image.dart';
import '../widgets/option_button.dart';
import '../widgets/streak_badge.dart';

/// The gameplay screen — one screen, three states (question / correct / wrong),
/// shared across flag / currency / capital modes.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key, required this.controller});
  final GameController controller;

  /// Fixed height for the result area, reserved whether answered or not, so
  /// the result text + next button appear in place with no layout shift.
  static const double _resultSlotHeight = 92;

  String get _subtitle {
    final mode = controller.mode.titleFa;
    final region = controller.region;
    return region == null ? mode : '$mode · $region';
  }

  Color get _badgeColor => switch (controller.state) {
    AnswerState.correct => AppColors.correct,
    AnswerState.wrong => AppColors.wrong,
    AnswerState.unanswered => AppColors.ink,
  };

  OptionVisual _visualFor(int index, Question q) {
    if (!controller.answered) return OptionVisual.idle;
    if (index == q.correctIndex) return OptionVisual.correct;
    if (index == controller.selectedIndex) return OptionVisual.wrong;
    return OptionVisual.dim;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.finished) {
                  return _Complete(
                    controller: controller,
                    onExit: () => Navigator.of(context).pop(),
                  );
                }
                final q = controller.question!;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // header: exit at start edge (right in RTL), subtitle at
                      // end edge (left in RTL), current record absolute center
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _ExitButton(
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              _subtitle,
                              style: const TextStyle(
                                fontFamily: AppTheme.sans,
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          _CurrentRecord(
                            value: controller.record,
                            beat: controller.justBeatRecord,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // live streak under center
                      Center(
                        child: StreakBadge(
                          label: '',
                          value: toPersianDigits(controller.streak),
                          color: _badgeColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // prompt block centered in the free space above the options
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) => SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(minHeight: c.maxHeight),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _Prompt(question: q),
                                    const SizedBox(height: 8),
                                    Text(
                                      q.promptFa,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.sans,
                                        fontSize: 14,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      for (var i = 0; i < q.options.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        OptionButton(
                          label: q.options[i],
                          visual: _visualFor(i, q),
                          onTap: controller.answered
                              ? null
                              : () => controller.answer(i),
                        ),
                      ],
                      // Reserve the result slot at all times so selecting an
                      // option swaps content in place without shifting layout.
                      const SizedBox(height: 18),
                      SizedBox(
                        height: _resultSlotHeight,
                        child: controller.answered
                            ? _Result(controller: controller)
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Round-complete screen: score summary + best record, then Play again
/// (primary) and Exit. Shown once the whole pool has been walked.
class _Complete extends StatelessWidget {
  const _Complete({required this.controller, required this.onExit});
  final GameController controller;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final correct = toPersianDigits(controller.correct);
    final total = toPersianDigits(controller.total);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تمام شد!',
            textAlign: TextAlign.center,
            style: AppTheme.handSize(40),
          ),
          const SizedBox(height: 18),
          _Panel(
            children: [
              Text(
                '$correct از $total درست',
                style: AppTheme.handSize(28, color: AppColors.correct),
              ),
              const SizedBox(height: 8),
              Text(
                'رکورد: ${toPersianDigits(controller.record)}',
                style: const TextStyle(
                  fontFamily: AppTheme.sans,
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _ActionButton(
            label: 'شروع مجدد',
            primary: true,
            onTap: controller.playAgain,
          ),
          const SizedBox(height: 12),
          _ActionButton(label: 'خروج', primary: false, onTap: onExit),
        ],
      ),
    );
  }
}

/// Full-width sticker button. [primary] fills with the ink color (Play again);
/// otherwise it's an outline (Exit).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressSink(
      onTap: onTap,
      borderRadius: 24,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: primary ? AppColors.ink : AppColors.card,
          border: Border.all(color: AppColors.ink, width: 1.6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.sans,
            fontSize: 15,
            color: primary ? AppColors.card : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// The prompt block above the options — varies per mode.
class _Prompt extends StatelessWidget {
  const _Prompt({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    switch (question.mode) {
      case GameMode.flag:
        return FlagImage(assetPath: question.answer.flagAsset);
      case GameMode.map:
        return MapImage(assetPath: question.answer.mapAsset);
      case GameMode.currency:
        return _Panel(
          children: [
            const Text(
              'واحد پولِ',
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(question.answer.fa, style: AppTheme.handSize(40)),
            const SizedBox(height: 4),
            const Text(
              'کدام است؟',
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        );
      case GameMode.neighbor:
        return _Panel(
          children: [
            const Text(
              'کدام کشور همسایهٔ',
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(question.answer.fa, style: AppTheme.handSize(40)),
            const SizedBox(height: 4),
            const Text(
              'نیست؟',
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        );
      case GameMode.capital:
        final toCountry =
            question.direction == CapitalDirection.capitalToCountry;
        return _Panel(
          children: [
            const Text(
              'پایتختِ',
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              toCountry ? question.answer.capital : question.answer.fa,
              style: AppTheme.handSize(40),
            ),
            const SizedBox(height: 4),
            Text(
              toCountry ? 'مربوط به کدام کشور است؟' : 'کدام است؟',
              style: const TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        );
    }
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.highlight,
        border: Border.all(color: AppColors.ink, width: 1.6),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(0, 2), blurRadius: 0),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Wraps a hard-shadow button so it sinks down on press (shadow collapses),
/// matching the option cards' "stamp" feel. Used by every game button.
class _PressSink extends StatefulWidget {
  const _PressSink({
    required this.onTap,
    required this.borderRadius,
    required this.child,
  });

  final VoidCallback onTap;
  final double borderRadius;
  final Widget child;

  @override
  State<_PressSink> createState() => _PressSinkState();
}

class _PressSinkState extends State<_PressSink> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(0, _pressed ? 0 : 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Big round sticker exit button in the header — icon only, pops to the menu.
class _ExitButton extends StatelessWidget {
  const _ExitButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressSink(
      onTap: onTap,
      borderRadius: 24,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.ink, width: 1.8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.close, size: 24, color: AppColors.ink),
      ),
    );
  }
}

/// Current (per-mode) record, centered below the header. Pulses + flashes
/// green for one beat when the player just set a new record.
class _CurrentRecord extends StatefulWidget {
  const _CurrentRecord({required this.value, required this.beat});
  final int value;
  final bool beat;

  @override
  State<_CurrentRecord> createState() => _CurrentRecordState();
}

class _CurrentRecordState extends State<_CurrentRecord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 60),
  ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    if (widget.beat) _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(_CurrentRecord old) {
    super.didUpdateWidget(old);
    if (widget.beat && !old.beat) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final active = widget.beat && _ctrl.isAnimating;
          final color = active ? AppColors.correct : AppColors.ink;
          final bg = active ? AppColors.correctBg : AppColors.postit;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: color, width: 1.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🔥 رکورد ${toPersianDigits(widget.value)}',
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Result line + next button (correct => green/«سوال بعدی», wrong => red/«ادامه»).
class _Result extends StatelessWidget {
  const _Result({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final correct = controller.state == AnswerState.correct;
    final q = controller.question!;
    final message = correct
        ? 'آفرین! درست بود'
        : 'اشتباه شد — پاسخ: ${q.options[q.correctIndex]}';
    final color = correct ? AppColors.correct : AppColors.wrong;
    final buttonText = correct ? 'سوال بعدی ›' : 'ادامه ›';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.handSize(22, color: color),
        ),
        const SizedBox(height: 8),
        _PressSink(
          onTap: controller.next,
          borderRadius: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.ink, width: 1.6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontFamily: AppTheme.sans, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
