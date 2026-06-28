import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/quiz_repository.dart';
import '../../data/seasons.dart';
import '../../state/ad_service.dart';
import '../../state/level_progress.dart';
import '../../state/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/option_button.dart';
import '../../widgets/press_sink.dart';
import '../quiz/quiz_exit_button.dart';
import '../quiz/quiz_prompt.dart';
import 'level_complete.dart';

/// Plays one finite level: [LevelDef.questionCount] questions, 3 lives, four
/// options each. A wrong answer costs a life; the level ends when the questions
/// run out OR lives hit zero. Stars earned = lives remaining at the end.
///
/// The question *set* is fixed per level: it's generated once with an RNG seeded
/// on the level's [LevelDef.globalIndex], so a given level always asks the same
/// countries. Only the *order* is randomised — the set is shuffled with a fresh
/// unseeded RNG at the start of every play (and on retry), so the questions come
/// up in a different sequence each time but the level's content never changes.
///
/// This is deliberately separate from the endless [GameController]: a level has
/// fixed length, a life budget, and a star result — none of which the streak
/// controller models. It reuses the shared draw logic ([QuizRepository]) and the
/// quiz widgets ([QuizPrompt], [OptionButton]).
class LevelPlayScreen extends StatefulWidget {
  const LevelPlayScreen({
    super.key,
    required this.level,
    required this.repo,
    required this.progress,
  });

  final LevelDef level;
  final QuizRepository repo;
  final LevelProgress progress;

  @override
  State<LevelPlayScreen> createState() => _LevelPlayScreenState();
}

class _LevelPlayScreenState extends State<LevelPlayScreen> {
  static const int _maxLives = 3;
  static const double _resultSlotHeight = 64;

  /// The level's fixed question set, built once (seeded). Order is reshuffled
  /// per play; this list itself is rebuilt only when the level changes.
  late List<Question> _questions;

  int _index = 0;
  int _lives = _maxLives;
  int _correctCount = 0;
  int _mistakes = 0;

  /// Duolingo-style mistake replay. Questions missed during the main run are
  /// queued here and re-asked after the set is exhausted (only if the player
  /// still has lives). A question correct on replay leaves the queue; missed
  /// again it goes to the back. Replay answers don't cost lives or change the
  /// score — the life/mistake was already counted on the first miss.
  final List<Question> _wrongQueue = [];
  bool _reviewing = false;

  /// Queue size at the moment review started — drives the review progress bar.
  int _reviewTotal = 0;

  AnswerState _state = AnswerState.unanswered;
  int? _selectedIndex;
  bool _done = false;

  /// Set on a successful finish: the play view stays mounted while the progress
  /// bar runs out to 100% and the end-of-bar sparks fire. Once that celebratory
  /// beat plays out we flip [_done] and the result screen takes over. A failed
  /// finish skips this and goes straight to the result.
  bool _finishing = false;

  // Cache the prompt block by question identity so per-answer rebuilds don't
  // re-mount the SVG (same trick as the main quiz screen).
  Question? _promptQuestion;
  Widget? _promptCache;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestionSet();
    _questions.shuffle(); // random order, fresh each play
  }

  /// The current question. During the main run it's the indexed question; in
  /// the review phase it's the front of the wrong queue. Null once both are
  /// exhausted.
  Question? get _question {
    if (_reviewing) {
      return _wrongQueue.isNotEmpty ? _wrongQueue.first : null;
    }
    return _index < _questions.length ? _questions[_index] : null;
  }

  /// Generate the level's fixed question set with an RNG seeded on the level
  /// index, so the same level always asks the same countries. Drawing stops at
  /// [LevelDef.questionCount] or when the pool / stub data runs dry.
  List<Question> _buildQuestionSet() {
    final rng = Random(widget.level.globalIndex);
    final seen = <String>{};
    final out = <Question>[];
    while (out.length < widget.level.questionCount) {
      final q = switch (widget.level.kind) {
        LevelKind.color => widget.repo.colorQuestion(exclude: seen, rng: rng),
        LevelKind.name => widget.repo.next(
          widget.level.mode,
          region: widget.level.region,
          exclude: seen,
          rng: rng,
        ),
      };
      if (q == null) break; // pool exhausted
      seen.add(q.answer.code);
      out.add(q);
    }
    return out;
  }

  Widget _promptFor(Question q) {
    if (!identical(q, _promptQuestion)) {
      _promptQuestion = q;
      _promptCache = RepaintBoundary(child: QuizPrompt(question: q));
    }
    return _promptCache!;
  }

  bool get _answered => _state != AnswerState.unanswered;

  /// Effective length of this level — the fixed set may be shorter than the
  /// requested [LevelDef.questionCount] when the pool runs dry.
  int get _totalQuestions => _questions.length;

  void _answer(int i) {
    if (_answered) return;
    final q = _question!;
    final correct = i == q.correctIndex;

    // Review phase: no life/score effect — just track whether it can leave the
    // queue. The dequeue/requeue happens in `_next` once the result is shown.
    if (_reviewing) {
      setState(() {
        _selectedIndex = i;
        _state = correct ? AnswerState.correct : AnswerState.wrong;
        if (correct) {
          SoundService.instance.playCorrect();
        } else {
          SoundService.instance.playWrong();
        }
      });
      return;
    }

    setState(() {
      _selectedIndex = i;
      if (correct) {
        _state = AnswerState.correct;
        _correctCount += 1;
        SoundService.instance.playCorrect();
      } else {
        _state = AnswerState.wrong;
        _lives -= 1;
        _mistakes += 1;
        _wrongQueue.add(q); // re-asked after the main run
        SoundService.instance.playWrong();
        if (_mistakes % 3 == 0) AdService.instance.showInterstitial();
      }
    });
  }

  void _next() {
    // Out of lives → fail the level immediately (skip the review).
    if (_lives <= 0) {
      _finish();
      return;
    }

    if (_reviewing) {
      // Pop the just-answered question; requeue it on a miss so it comes back.
      final q = _wrongQueue.removeAt(0);
      if (_state == AnswerState.wrong) _wrongQueue.add(q);
      if (_wrongQueue.isEmpty) {
        _finish();
        return;
      }
      setState(() {
        _state = AnswerState.unanswered;
        _selectedIndex = null;
      });
      return;
    }

    // Main run exhausted: replay missed questions before finishing.
    if (_index + 1 >= _questions.length) {
      if (_wrongQueue.isNotEmpty) {
        setState(() {
          _reviewing = true;
          _reviewTotal = _wrongQueue.length;
          _state = AnswerState.unanswered;
          _selectedIndex = null;
        });
        return;
      }
      _finish();
      return;
    }
    setState(() {
      _index += 1;
      _state = AnswerState.unanswered;
      _selectedIndex = null;
    });
  }

  // Bar fill tween (matches _ProgressBar) + sparks linger before the result.
  static const _finishBarFill = Duration(milliseconds: 400);
  static const _finishSparkHold = Duration(milliseconds: 700);

  void _finish() {
    final passed = _lives > 0;
    final stars = passed ? _lives : 0;
    widget.progress.recordResult(
      widget.level.globalIndex,
      stars,
      passed: passed,
    );

    // Fail: no celebration, drop straight to the result.
    if (!passed) {
      setState(() => _done = true);
      return;
    }

    // Pass: keep the play view up so the bar animates to 100% and the sparks
    // fire, then hand off to the result screen.
    setState(() {
      _finishing = true;
      _state = AnswerState.unanswered;
      _selectedIndex = null;
    });
    Future.delayed(_finishBarFill + _finishSparkHold, () {
      if (mounted) setState(() => _done = true);
    });
  }

  /// Restart the current level from scratch (retry after a fail). Same fixed
  /// question set, freshly reshuffled into a new order.
  void _retry() {
    setState(() {
      _questions.shuffle();
      _index = 0;
      _lives = _maxLives;
      _correctCount = 0;
      _mistakes = 0;
      _wrongQueue.clear();
      _reviewing = false;
      _reviewTotal = 0;
      _state = AnswerState.unanswered;
      _selectedIndex = null;
      _promptQuestion = null;
      _promptCache = null;
      _done = false;
      _finishing = false;
    });
  }

  /// The level after this one in the flat catalog, or null if this is the last.
  LevelDef? get _nextLevel {
    final i = widget.level.globalIndex; // 1-based
    return i < SeasonCatalog.allLevels.length
        ? SeasonCatalog.allLevels[i]
        : null;
  }

  /// Replace the play screen with the next level (so back returns to the grid,
  /// not a stack of finished levels).
  void _goNext() {
    final next = _nextLevel;
    if (next == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LevelPlayScreen(
          level: next,
          repo: widget.repo,
          progress: widget.progress,
        ),
      ),
    );
  }

  OptionVisual _visualFor(int i, Question q) {
    if (!_answered) return OptionVisual.idle;
    if (i == q.correctIndex) return OptionVisual.correct;
    if (i == _selectedIndex) return OptionVisual.wrong;
    return OptionVisual.dim;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            // Empty set (pool ran dry) can't be played — fall straight to the
            // result screen rather than dereferencing a null question.
            child: (_done || _questions.isEmpty)
                ? LevelComplete(
                    level: widget.level,
                    stars: _lives > 0 ? _lives : 0,
                    correct: _correctCount,
                    total: _totalQuestions,
                    passed: _lives > 0,
                    // On a pass, offer the next level (unless this is the last).
                    onNext: (_lives > 0 && _nextLevel != null) ? _goNext : null,
                    // On a fail, offer a retry.
                    onRetry: _lives > 0 ? null : _retry,
                    onExit: () => Navigator.of(context).pop(),
                  )
                : _buildPlay(context),
          ),
        ),
      ),
    );
  }

  Widget _buildPlay(BuildContext context) {
    // While finishing, the question content is gone — only the header (with the
    // filling bar + sparks) stays up. Keep the prompt/options out of the tree so
    // we never deref a now-null question.
    final q = _finishing ? null : _question!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          if (q != null) ...[
            const SizedBox(height: 14),
            _buildPromptArea(q),
            _buildOptionArea(q),
          ] else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              QuizExitButton(onTap: () => Navigator.of(context).pop()),
              // Lives — hearts, dim once spent.
              _LivesRow(lives: _lives, max: _maxLives),
            ],
          ),
          const SizedBox(height: 18),
          // Progress bar — fills as questions are answered. In review it shows
          // a distinct fill plus a "repeat your mistakes" banner.
          _ProgressBar(
            value: _progressValue,
            review: _reviewing,
            sparkle: _finishing,
          ),
          if (_reviewing) ...[
            const SizedBox(height: 10),
            const Text(
              'مرور اشتباه‌ها',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Bar fill: one continuous progress across the whole level (main run +
  /// review). Never resets when review starts — it keeps climbing. Total span
  /// is the main set plus the originally-missed count; review fill advances as
  /// the queue drains (requeued misses just pause it, don't pull it back).
  double get _progressValue {
    if (_finishing) return 1.0; // run the bar out before the result screen
    final span = _totalQuestions + _reviewTotal;
    if (span == 0) return 0;
    final cleared = _reviewing
        ? _totalQuestions + (_reviewTotal - _wrongQueue.length)
        : _index;
    return (cleared / span).clamp(0.0, 1.0);
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

  Widget _buildOptionArea(Question q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                  celebrate: _selectedIndex == q.correctIndex,
                  onTap: _answered ? null : () => _answer(i),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(
            height: _resultSlotHeight,
            child: _answered ? _LevelNextButton(onTap: _next) : null,
          ),
        ),
      ],
    );
  }
}

/// Reuses the answer state enum shape locally (correct/wrong/unanswered).
enum AnswerState { unanswered, correct, wrong }

/// Horizontal progress bar that animates its fill when [value] (0–1) changes.
/// When [sparkle] turns true the bar runs out to full and, once the fill lands,
/// a one-shot burst of sparks fires at the bar's trailing end.
class _ProgressBar extends StatefulWidget {
  const _ProgressBar({
    required this.value,
    this.review = false,
    this.sparkle = false,
  });

  final double value;

  /// Review phase tints the fill so the bar reads as a different stage.
  final bool review;

  /// Fires the end-of-bar celebration sparks once the fill reaches 100%.
  final bool sparkle;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  static const _barHeight = 12.0;

  // Matches the fill tween below so the burst pops as the bar lands on full.
  static const _fillDuration = Duration(milliseconds: 400);

  late final AnimationController _sparks = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didUpdateWidget(_ProgressBar old) {
    super.didUpdateWidget(old);
    if (widget.sparkle && !old.sparkle) {
      // Wait for the fill to reach the end, then burst.
      Future.delayed(_fillDuration, () {
        if (mounted) _sparks.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _sparks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.review ? AppColors.postitBorder : AppColors.ink;
    final bar = Container(
      height: _barHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dimBorder, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        // Inner radius = outer minus border so corners stay concentric.
        borderRadius: BorderRadius.circular(1),
        child: Stack(
          children: [
            Container(color: AppColors.highlight),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: widget.value.clamp(0.0, 1.0)),
              duration: _fillDuration,
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v,
                alignment: AlignmentDirectional.centerStart,
                child: Container(color: fill),
              ),
            ),
          ],
        ),
      ),
    );

    // Overlay the spark burst at the trailing (end) edge of the bar, allowing
    // it to spill above/below without clipping.
    return Stack(
      clipBehavior: Clip.none,
      alignment: AlignmentDirectional.centerEnd,
      children: [
        bar,
        if (widget.sparkle)
          PositionedDirectional(
            end: 0,
            top: -14,
            bottom: -14,
            child: Center(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _sparks,
                  builder: (context, _) => CustomPaint(
                    size: const Size(40, 40),
                    painter: _SparkPainter(_sparks.value),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A radial burst of short spark lines that shoot out and fade. [t] is 0→1.
class _SparkPainter extends CustomPainter {
  _SparkPainter(this.t);

  final double t;

  static const _count = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOut.transform(t);
    final reach = size.width / 2;
    final opacity = (1 - t).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = AppColors.postitBorder.withValues(alpha: opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < _count; i++) {
      final angle = (i / _count) * 2 * pi;
      final inner = 0.35 * reach * eased;
      final outer = reach * eased;
      final dir = Offset(cos(angle), sin(angle));
      canvas.drawLine(center + dir * inner, center + dir * outer, paint);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.t != t;
}

/// Three hearts; spent lives render hollow. When a life is lost the heart that
/// just emptied plays a break animation (a quick shake, scale bump, and a
/// 💔 → 🤍 swap) so the loss reads clearly.
class _LivesRow extends StatefulWidget {
  const _LivesRow({required this.lives, required this.max});
  final int lives;
  final int max;

  @override
  State<_LivesRow> createState() => _LivesRowState();
}

class _LivesRowState extends State<_LivesRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  late int _prevLives = widget.lives;

  /// Index of the heart currently breaking (the one just lost), or null.
  int? _breaking;

  // Scale: bump up then settle. Shake: horizontal wobble. Both run together.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 30),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.4,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 70,
    ),
  ]).animate(_ctrl);

  late final Animation<double> _shake = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 4.0, end: -3.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -3.0, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void didUpdateWidget(_LivesRow old) {
    super.didUpdateWidget(old);
    if (widget.lives < _prevLives) {
      // The heart at the new `lives` index is the one that just emptied.
      _breaking = widget.lives;
      _ctrl.forward(from: 0);
    }
    _prevLives = widget.lives;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// While breaking, show 💔 mid-animation; otherwise the resting glyph.
  String _glyph(int i) {
    if (i < widget.lives) return '❤️';
    if (i == _breaking && _ctrl.isAnimating) return '💔';
    return '🤍';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.max; i++)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final active = i == _breaking;
                final dx = active ? _shake.value : 0.0;
                final scale = active ? _scale.value : 1.0;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: Transform.scale(
                    scale: scale,
                    child: Text(
                      _glyph(i),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// The "next" button shown under the options after answering. Mirrors the main
/// quiz's result button but drives the level flow.
class _LevelNextButton extends StatelessWidget {
  const _LevelNextButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: PressSink(
          onTap: onTap,
          borderRadius: 24,
          borderWidth: 1.6,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
          child: const Text(
            'ادامه ›',
            style: TextStyle(fontFamily: AppTheme.sans, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
