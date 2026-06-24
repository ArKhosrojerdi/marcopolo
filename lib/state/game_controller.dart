import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quiz_repository.dart';

enum AnswerState { unanswered, correct, wrong }

/// Holds the live quiz session: current question, streak, persisted record,
/// and the selected/answer state. Endless mode — never ends.
class GameController extends ChangeNotifier {
  GameController(this._repo, this._prefs) {
    for (final m in GameMode.values) {
      _records[m] = _prefs.getInt(_recordKey(m)) ?? 0;
    }
  }

  final QuizRepository _repo;
  final SharedPreferences _prefs;

  /// Per-category record key. Each [GameMode] keeps its own best streak.
  static String _recordKey(GameMode mode) => 'streak_record_${mode.name}';

  late GameMode _mode;
  String? _region;
  Question? _question;
  int _streak = 0;
  final Map<GameMode, int> _records = {};
  AnswerState _state = AnswerState.unanswered;
  int? _selectedIndex;

  GameMode get mode => _mode;
  String? get region => _region;
  Question? get question => _question;
  int get streak => _streak;

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
  void start(GameMode mode, {String? region}) {
    _mode = mode;
    _region = region;
    _streak = 0;
    _state = AnswerState.unanswered;
    _selectedIndex = null;
    _question = _repo.next(mode, region: region);
    notifyListeners();
  }

  /// User taps an option. Evaluates and updates streak/record.
  void answer(int index) {
    if (answered) return;
    _selectedIndex = index;
    final q = _question!;
    if (index == q.correctIndex) {
      _state = AnswerState.correct;
      _streak += 1;
      if (_streak > record) {
        _records[_mode] = _streak;
        _prefs.setInt(_recordKey(_mode), _streak);
      }
    } else {
      _state = AnswerState.wrong;
      _streak = 0;
    }
    notifyListeners();
  }

  /// Advance to the next question (after answering).
  void next() {
    final prev = _question?.answer;
    _state = AnswerState.unanswered;
    _selectedIndex = null;
    _question = _repo.next(_mode, region: _region, avoid: prev);
    notifyListeners();
  }
}
