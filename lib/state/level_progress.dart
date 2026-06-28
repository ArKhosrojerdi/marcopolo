import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seasons.dart';

/// Persistent progress for the levels ("مراحل") game mode.
///
/// Three things are tracked, all in [SharedPreferences]:
///  * `level_played_<i>`  — bool, whether level i has ever been played at all
///    (pass or fail). Drives the season's "X of Y played" progress count.
///  * `level_passed_<i>`  — bool, whether level i has ever been *cleared* (ended
///    with at least one life left). A level unlocks once the level before it has
///    been passed — failing a level no longer unlocks the next.
///  * `level_stars_<i>`   — int 0..3, the best star result on level i. Stars =
///    lives remaining when the level ends (start with 3, −1 per wrong answer).
///
/// The 3-star count and total-played count are derived, so the only achievement
/// state that needs its own storage is per-game-mode best records, which the
/// existing [GameController] already owns. This class therefore stays the single
/// source of truth for level unlock/star state and exposes derived counters the
/// achievements screen reads.
class LevelProgress extends ChangeNotifier {
  LevelProgress(this._prefs);

  final SharedPreferences _prefs;

  static String _playedKey(int i) => 'level_played_$i';
  static String _passedKey(int i) => 'level_passed_$i';
  static String _starsKey(int i) => 'level_stars_$i';

  bool hasPlayed(int globalIndex) =>
      _prefs.getBool(_playedKey(globalIndex)) ?? false;

  bool hasPassed(int globalIndex) =>
      _prefs.getBool(_passedKey(globalIndex)) ?? false;

  int starsFor(int globalIndex) => _prefs.getInt(_starsKey(globalIndex)) ?? 0;

  /// A level is unlocked if it's the very first level, or the previous level has
  /// been *passed* (cleared with at least one life left).
  /// In debug builds all levels are unlocked for testing.
  bool isUnlocked(int globalIndex) =>
      kDebugMode || globalIndex <= 1 || hasPassed(globalIndex - 1);

  /// Record a finished level: mark it played, mark it passed when [passed],
  /// and keep the best star result. Unlocks the next level (via [hasPassed])
  /// only on a pass.
  Future<void> recordResult(int globalIndex, int stars,
      {required bool passed}) async {
    await _prefs.setBool(_playedKey(globalIndex), true);
    if (passed) await _prefs.setBool(_passedKey(globalIndex), true);
    if (stars > starsFor(globalIndex)) {
      await _prefs.setInt(_starsKey(globalIndex), stars);
    }
    notifyListeners();
  }

  /// Total levels played at least once (for achievements + season progress).
  int get playedCount {
    var n = 0;
    for (var i = 1; i <= SeasonCatalog.totalLevels; i++) {
      if (hasPlayed(i)) n++;
    }
    return n;
  }

  /// Levels completed with a perfect 3-star (no wrong answers).
  int get threeStarCount {
    var n = 0;
    for (var i = 1; i <= SeasonCatalog.totalLevels; i++) {
      if (starsFor(i) >= 3) n++;
    }
    return n;
  }

  /// Levels played within a season (for the season list subtitle / progress).
  int playedInSeason(SeasonDef season) {
    var n = 0;
    for (final l in season.levels) {
      if (hasPlayed(l.globalIndex)) n++;
    }
    return n;
  }
}
