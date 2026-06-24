import 'package:flutter/material.dart';

import '../data/quiz_repository.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/flag_image.dart';
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
                final q = controller.question!;
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // header: exit button + subtitle, then live streak + record
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _ExitButton(
                                  onTap: () => Navigator.of(context).pop()),
                              const SizedBox(width: 8),
                              Text(_subtitle,
                                  style: const TextStyle(
                                      fontFamily: AppTheme.sans,
                                      fontSize: 12,
                                      color: AppColors.muted)),
                            ],
                          ),
                          Row(
                            children: [
                              StreakBadge(
                                label: '',
                                value: toPersianDigits(controller.streak),
                                color: _badgeColor,
                              ),
                              const SizedBox(width: 8),
                              StreakBadge(
                                label: 'رکورد',
                                value: toPersianDigits(controller.record),
                                color: AppColors.ink,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _Prompt(question: q),
                      const SizedBox(height: 8),
                      Text(q.promptFa,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: AppTheme.sans,
                              fontSize: 14,
                              color: AppColors.ink)),
                      const SizedBox(height: 18),
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

/// The prompt block above the options — varies per mode.
class _Prompt extends StatelessWidget {
  const _Prompt({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    switch (question.mode) {
      case GameMode.flag:
      case GameMode.map:
        return FlagImage(assetPath: question.answer.flagAsset);
      case GameMode.currency:
        return _Panel(
          children: [
            Text(
              question.answer.currencySymbol.isNotEmpty
                  ? question.answer.currencySymbol
                  : '¤',
              style: AppTheme.handSize(46),
            ),
            const SizedBox(height: 6),
            Text(question.answer.currencyName, style: AppTheme.handSize(24)),
            const SizedBox(height: 6),
            const Text('نماد در صورت وجود نمایش داده می‌شود',
                style: TextStyle(
                    fontFamily: AppTheme.sans,
                    fontSize: 11,
                    color: AppColors.faint)),
          ],
        );
      case GameMode.capital:
        return _Panel(
          children: [
            const Text('پایتختِ',
                style: TextStyle(
                    fontFamily: AppTheme.sans,
                    fontSize: 12,
                    color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(question.answer.fa, style: AppTheme.handSize(40)),
            const SizedBox(height: 4),
            const Text('کدام است؟',
                style: TextStyle(
                    fontFamily: AppTheme.sans,
                    fontSize: 12,
                    color: AppColors.muted)),
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

/// Sticker-style exit button in the header — pops back to the menu.
class _ExitButton extends StatelessWidget {
  const _ExitButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.ink, width: 1.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: AppColors.ink, offset: Offset(0, 2), blurRadius: 0),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, size: 14, color: AppColors.ink),
            SizedBox(width: 3),
            Text('خروج',
                style: TextStyle(
                    fontFamily: AppTheme.sans,
                    fontSize: 12,
                    color: AppColors.ink)),
          ],
        ),
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
        Text(message,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.handSize(22, color: color)),
        const SizedBox(height: 8),
        InkWell(
          onTap: controller.next,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.ink, width: 1.6),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.ink, offset: Offset(0, 2), blurRadius: 0),
              ],
            ),
            child: Text(buttonText,
                style: const TextStyle(
                    fontFamily: AppTheme.sans, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}
