import 'package:flutter/material.dart';

import '../data/quiz_repository.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/hard_keyboard.dart';
import '../widgets/option_button.dart';
import '../widgets/streak_badge.dart';
import '../widgets/word_blanks.dart';
import 'quiz/current_record.dart';
import 'quiz/quiz_complete.dart';
import 'quiz/quiz_exit_button.dart';
import 'quiz/quiz_prompt.dart';
import 'quiz/quiz_result.dart';

/// The gameplay screen — one screen, three states (question / correct / wrong),
/// shared across flag / currency / capital modes.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  /// Fixed height for the result area, reserved whether answered or not, so
  /// the result text + next button appear in place with no layout shift.
  static const double _resultSlotHeight = 64;

  String _typed = '';

  GameController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    // Reset typed input when a new question loads (state goes back to unanswered).
    if (!_ctrl.answered) {
      setState(() => _typed = '');
    }
  }

  String get _subtitle {
    final mode = _ctrl.mode.titleFa;
    final region = _ctrl.region;
    return region == null ? mode : '$mode · $region';
  }

  Color get _badgeColor => switch (_ctrl.state) {
    AnswerState.correct => AppColors.correct,
    AnswerState.wrong => AppColors.wrong,
    AnswerState.unanswered => AppColors.ink,
  };

  OptionVisual _visualFor(int index, Question q) {
    if (!_ctrl.answered) return OptionVisual.idle;
    if (index == q.correctIndex) return OptionVisual.correct;
    if (index == _ctrl.selectedIndex) return OptionVisual.wrong;
    return OptionVisual.dim;
  }

  void _onChar(String char) {
    final q = _ctrl.question!;
    if (_typed.length >= stripSpaces(q.correctAnswer).length) return;
    setState(() => _typed += char);
  }

  void _onBackspace() {
    if (_typed.isEmpty) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  void _onSubmit() {
    _ctrl.answerText(_typed);
  }

  void _onSkip() {
    _ctrl.answerText('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListenableBuilder(
              listenable: _ctrl,
              builder: (context, _) {
                if (_ctrl.finished) {
                  return QuizComplete(
                    controller: _ctrl,
                    onExit: () => Navigator.of(context).pop(),
                  );
                }
                final q = _ctrl.question!;
                // Neighbor mode is always option-based — its hard variant asks
                // the player to pick the country, not type it. So the typing
                // keyboard only appears for the other hard modes.
                final useKeyboard = _ctrl.difficulty == GameDifficulty.hard &&
                    q.mode != GameMode.neighbor;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Stack(
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
                              value: _ctrl.record,
                              beat: _ctrl.justBeatRecord,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: StreakBadge(
                          label: '',
                          value: toPersianDigits(_ctrl.streak),
                          color: _badgeColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                      ),
                      if (useKeyboard) ...[
                        Center(
                          child: WordBlanks(
                            length: stripSpaces(q.correctAnswer).length,
                            typed: _typed,
                            state: _ctrl.answered
                                ? (_ctrl.state == AnswerState.correct)
                                : null,
                            revealAnswer: _ctrl.state == AnswerState.wrong
                                ? q.correctAnswer
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < q.options.length; i++) ...[
                                if (i > 0) const SizedBox(height: 12),
                                OptionButton(
                                  label: q.options[i],
                                  visual: _visualFor(i, q),
                                  celebrate:
                                      _ctrl.selectedIndex == q.correctIndex,
                                  onTap: _ctrl.answered
                                      ? null
                                      : () => _ctrl.answer(i),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (useKeyboard) ...[
                        HardKeyboard(
                          onChar: _onChar,
                          onBackspace: _onBackspace,
                          onSubmit: _onSubmit,
                          onSkip: _onSkip,
                          submitEnabled:
                              _typed.length ==
                              stripSpaces(q.correctAnswer).length,
                          disabled: _ctrl.answered,
                        ),
                        const SizedBox(height: 4),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: SizedBox(
                          height: _resultSlotHeight,
                          child: _ctrl.answered
                              ? QuizResult(controller: _ctrl)
                              : null,
                        ),
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
