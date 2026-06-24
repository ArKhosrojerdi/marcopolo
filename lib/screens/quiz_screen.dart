import 'package:flutter/material.dart';

import '../data/quiz_repository.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/option_button.dart';
import '../widgets/streak_badge.dart';
import 'quiz/current_record.dart';
import 'quiz/quiz_complete.dart';
import 'quiz/quiz_exit_button.dart';
import 'quiz/quiz_prompt.dart';
import 'quiz/quiz_result.dart';

/// The gameplay screen — one screen, three states (question / correct / wrong),
/// shared across flag / currency / capital modes.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key, required this.controller});
  final GameController controller;

  /// Fixed height for the result area, reserved whether answered or not, so
  /// the result text + next button appear in place with no layout shift.
  static const double _resultSlotHeight = 64;

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
                  return QuizComplete(
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
                            child: QuizExitButton(
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
                          CurrentRecord(
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
                              constraints: BoxConstraints(
                                minHeight: c.maxHeight,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [QuizPrompt(question: q)],
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
                          // Pop the correct card only when the player picked
                          // it; on a wrong answer the revealed correct card
                          // stays still and only the wrong card shakes.
                          celebrate: controller.selectedIndex == q.correctIndex,
                          onTap: controller.answered
                              ? null
                              : () => controller.answer(i),
                        ),
                      ],
                      // Reserve the result slot at all times so selecting an
                      // option swaps content in place without shifting layout.
                      SizedBox(
                        height: _resultSlotHeight,
                        child: controller.answered
                            ? QuizResult(controller: controller)
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
