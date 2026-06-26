import 'package:flutter/material.dart';

import '../data/quiz_repository.dart';
import '../state/ad_service.dart';
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

  /// The prompt block (flag/map SVG or text panel) depends only on the current
  /// [Question], not on [_typed] or answer state. Cache it by question identity
  /// so per-keystroke `setState`s don't rebuild — and crucially don't re-mount —
  /// the SVG widget.
  Question? _promptQuestion;
  Widget? _promptCache;

  Widget _promptFor(Question q) {
    if (!identical(q, _promptQuestion)) {
      _promptQuestion = q;
      _promptCache = RepaintBoundary(child: QuizPrompt(question: q));
    }
    return _promptCache!;
  }

  GameController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onControllerChange);
    // Show an interstitial every third wrong answer.
    _ctrl.onMistakeThreshold = AdService.instance.showInterstitial;
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChange);
    _ctrl.onMistakeThreshold = null;
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

  /// Neighbor mode is always option-based — its hard variant asks the player
  /// to pick the country, not type it. So the typing keyboard only appears for
  /// the other hard modes.
  bool _useKeyboard(Question q) =>
      _ctrl.difficulty == GameDifficulty.hard && q.mode != GameMode.neighbor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _ctrl,
          builder: (context, _) {
            if (_ctrl.finished) return _buildComplete(context);
            final q = _ctrl.question!;
            final useKeyboard = _useKeyboard(q);
            return Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 10),
                          Center(
                            child: StreakBadge(
                              label: '',
                              value: toPersianDigits(_ctrl.streak),
                              color: _badgeColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildPromptArea(q),
                          if (useKeyboard)
                            ..._buildTypingArea(q)
                          else
                            ..._buildOptionArea(q),
                        ],
                      ),
                    ),
                  ),
                ),
                if (useKeyboard) _buildKeyboard(q),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildComplete(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: QuizComplete(
          controller: _ctrl,
          onExit: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: QuizExitButton(onTap: () => Navigator.of(context).pop()),
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
          CurrentRecord(value: _ctrl.record, beat: _ctrl.justBeatRecord),
        ],
      ),
    );
  }

  Widget _buildPromptArea(Question q) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_promptFor(q)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Typing mode: word blanks + a fixed gap that reserves room for the
  /// bottom-pinned [HardKeyboard].
  List<Widget> _buildTypingArea(Question q) {
    return [
      Center(
        child: WordBlanks(
          length: stripSpaces(q.correctAnswer).length,
          typed: _typed,
          state: _ctrl.answered ? (_ctrl.state == AnswerState.correct) : null,
        ),
      ),
      const SizedBox(height: 12),
      const SizedBox(height: 220),
    ];
  }

  /// Option mode: answer buttons + a fixed-height result slot, reserved
  /// whether answered or not so the result appears in place with no shift.
  List<Widget> _buildOptionArea(Question q) {
    return [
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
                celebrate: _ctrl.selectedIndex == q.correctIndex,
                onTap: _ctrl.answered ? null : () => _ctrl.answer(i),
              ),
            ],
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SizedBox(
          height: _resultSlotHeight,
          child: _ctrl.answered ? QuizResult(controller: _ctrl) : null,
        ),
      ),
    ];
  }

  Widget _buildKeyboard(Question q) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: RepaintBoundary(
          child: HardKeyboard(
            onChar: _onChar,
            onBackspace: _onBackspace,
            onSubmit: _onSubmit,
            onSkip: _onSkip,
            onNext: _ctrl.next,
            correctAnswer: q.correctAnswer,
            submitEnabled:
                _typed.length == stripSpaces(q.correctAnswer).length,
            disabled: _ctrl.answered,
          ),
        ),
      ),
    );
  }
}
