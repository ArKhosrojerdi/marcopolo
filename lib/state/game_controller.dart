import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quiz_repository.dart';
import 'sound_service.dart';
import 'svg_prefetch.dart';

enum AnswerState { unanswered, correct, wrong }

/// Holds the live quiz session: current question, streak, persisted record,
/// and the selected/answer state. A round walks the whole pool with no
/// repeats; once every country has been asked the round is [finished].
class GameController extends ChangeNotifier {
  GameController(this._repo, this._prefs) {
    for (final m in GameMode.values) {
      _records[m] = _prefs.getInt(_recordKey(m)) ?? 0;
    }
  }

  final QuizRepository _repo;
  final SharedPreferences _prefs;

  /// The shared question source, exposed so the levels mode can draw from the
  /// same pool/generators without a second repository instance.
  QuizRepository get repo => _repo;

  /// Per-category record key. Each [GameMode] keeps its own best streak.
  static String _recordKey(GameMode mode) => 'streak_record_${mode.name}';

  late GameMode _mode;
  String? _region;
  CapitalDirection _direction = CapitalDirection.countryToCapital;
  GameDifficulty _difficulty = GameDifficulty.normal;
  Question? _question;
  int _streak = 0;
  final Map<GameMode, int> _records = {};
  AnswerState _state = AnswerState.unanswered;
  int? _selectedIndex;

  /// True only on the answer that pushed the streak past the previous record
  /// (for the "new record!" pulse). Cleared on [next].
  bool _justBeatRecord = false;

  /// Wrong answers so far this round. Every [_mistakesPerAd] of them fires
  /// [onMistakeThreshold] (used to show an interstitial ad).
  int _mistakes = 0;
  static const int _mistakesPerAd = 3;

  /// Invoked each time the mistake count hits a multiple of [_mistakesPerAd].
  /// Set by the UI layer, which owns the ad SDK. Kept out of the controller so
  /// game logic has no ad dependency.
  VoidCallback? onMistakeThreshold;

  /// Country codes already asked this round (never repeated within a round).
  final Set<String> _seen = {};
  int _correct = 0;
  int _total = 0;
  bool _finished = false;

  GameMode get mode => _mode;
  String? get region => _region;
  CapitalDirection get direction => _direction;
  GameDifficulty get difficulty => _difficulty;
  Question? get question => _question;
  int get streak => _streak;
  bool get justBeatRecord => _justBeatRecord;

  /// Round progress — correct answers, total answered, and whether the whole
  /// pool has been walked (round over).
  int get correct => _correct;
  int get total => _total;
  bool get finished => _finished;

  /// Best streak for the active mode.
  int get record => _records[_mode] ?? 0;

  /// Best streak for any given mode (for the home cards).
  int recordFor(GameMode mode) => _records[mode] ?? 0;

  /// Highest record across all categories (for the home header badge).
  int get bestRecord =>
      _records.values.fold(0, (max, v) => v > max ? v : max);
  AnswerState get state => _state;
  int? get selectedIndex => _selectedIndex;
  bool get answered => _state != AnswerState.unanswered;

  /// Start a fresh session. Streak resets to 0; record persists.
  void start(
    GameMode mode, {
    String? region,
    CapitalDirection direction = CapitalDirection.countryToCapital,
    GameDifficulty difficulty = GameDifficulty.normal,
  }) {
    _mode = mode;
    _region = region;
    _direction = direction;
    _difficulty = difficulty;
    _reset();
    _question = _repo.next(
      mode,
      region: region,
      exclude: _seen,
      direction: direction,
      difficulty: difficulty,
    );
    _seen.add(_question!.answer.code);
    _warmQuestionAsset(_question!);
    notifyListeners();
  }

  /// Primes the SVG cache for an image-backed question (flag/map) so the
  /// picture is ready when the widget mounts — no placeholder flash.
  void _warmQuestionAsset(Question q) {
    switch (q.mode) {
      case GameMode.flag:
        SvgPrefetch.warm(q.answer.flagAsset);
      case GameMode.map:
        SvgPrefetch.warm(q.answer.mapAsset);
      case GameMode.currency:
      case GameMode.capital:
      case GameMode.neighbor:
        break;
    }
  }

  /// Replay the same mode/region from scratch (from the completion screen).
  /// Streak resets to 0; record persists.
  void playAgain() =>
      start(_mode, region: _region, direction: _direction, difficulty: _difficulty);

  /// Hard mode: evaluate a typed answer against the correct label.
  void answerText(String input) {
    if (answered) return;
    _total += 1;
    final q = _question!;
    final match = normalizeAnswer(stripSpaces(input)) ==
        normalizeAnswer(stripSpaces(q.correctAnswer));
    if (match) {
      _selectedIndex = q.correctIndex;
      _state = AnswerState.correct;
      _correct += 1;
      _streak += 1;
      SoundService.instance.playCorrect();
      if (_streak > record) {
        _records[_mode] = _streak;
        _prefs.setInt(_recordKey(_mode), _streak);
        _justBeatRecord = true;
      }
    } else {
      _selectedIndex = -1;
      _state = AnswerState.wrong;
      _streak = 0;
      SoundService.instance.playWrong();
      _registerMistake();
    }
    notifyListeners();
  }

  /// Records a wrong answer and fires [onMistakeThreshold] on every third one.
  void _registerMistake() {
    _mistakes += 1;
    if (_mistakes % _mistakesPerAd == 0) onMistakeThreshold?.call();
  }

  /// Clears per-round session state (seen pool, score, streak).
  void _reset() {
    _streak = 0;
    _correct = 0;
    _total = 0;
    _mistakes = 0;
    _finished = false;
    _seen.clear();
    _state = AnswerState.unanswered;
    _selectedIndex = null;
    _justBeatRecord = false;
  }

  /// User taps an option. Evaluates and updates streak/record.
  void answer(int index) {
    if (answered) return;
    _selectedIndex = index;
    _total += 1;
    final q = _question!;
    if (index == q.correctIndex) {
      _state = AnswerState.correct;
      _correct += 1;
      _streak += 1;
      SoundService.instance.playCorrect();
      if (_streak > record) {
        _records[_mode] = _streak;
        _prefs.setInt(_recordKey(_mode), _streak);
        _justBeatRecord = true;
      }
    } else {
      _state = AnswerState.wrong;
      _streak = 0;
      SoundService.instance.playWrong();
      _registerMistake();
    }
    notifyListeners();
  }

  /// Advance to the next question (after answering). When the pool is
  /// exhausted the round is [finished] and the question is left in place.
  void next() {
    final q = _repo.next(
      _mode,
      region: _region,
      exclude: _seen,
      direction: _direction,
      difficulty: _difficulty,
    );
    if (q == null) {
      _finished = true;
      notifyListeners();
      return;
    }
    _state = AnswerState.unanswered;
    _selectedIndex = null;
    _justBeatRecord = false;
    _question = q;
    _seen.add(q.answer.code);
    _warmQuestionAsset(q);
    notifyListeners();
  }
}
