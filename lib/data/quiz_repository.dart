import 'dart:math';
import 'country.dart';

enum GameMode { flag, currency, map, capital, neighbor }

enum GameDifficulty { normal, hard }

/// Strip spaces, half-spaces (U+200C), and Arabic diacritics (U+064B–U+065F)
/// — used for blank-cell counting and answer comparison in hard mode.
String stripSpaces(String s) => s.replaceAll(RegExp(r'[‌ ً-ٟ]'), '');

/// Normalize Persian letter variants before comparison:
/// آ→ا  ئ→ی  ؤ→و
String normalizeAnswer(String s) => s
    .replaceAll('آ', 'ا')
    .replaceAll('ئ', 'ی')
    .replaceAll('ؤ', 'و');

/// Direction for the capital mode: show the country and ask its capital, or
/// show the capital and ask which country it belongs to.
enum CapitalDirection { countryToCapital, capitalToCountry }

extension GameModeInfo on GameMode {
  String get titleFa => switch (this) {
        GameMode.flag => 'پرچم',
        GameMode.currency => 'واحد پول',
        GameMode.map => 'نقشه کشور',
        GameMode.capital => 'پایتخت',
        GameMode.neighbor => 'همسایه‌ها',
      };

  /// Whether this mode has a region (continent) selection step. Flag + map +
  /// neighbor.
  bool get hasRegionStep =>
      this == GameMode.flag ||
      this == GameMode.map ||
      this == GameMode.neighbor;

  /// Whether this mode has a direction selection step. Capital only.
  bool get hasDirectionStep => this == GameMode.capital;
}

/// A single generated quiz question.
class Question {
  final GameMode mode;
  final Country answer;
  final List<String> options; // option labels (shuffled)
  final int correctIndex;

  /// Direction for capital questions; null for other modes.
  final CapitalDirection? direction;

  /// The exact label the player must type in hard mode.
  final String correctAnswer;

  const Question({
    required this.mode,
    required this.answer,
    required this.options,
    required this.correctIndex,
    required this.correctAnswer,
    this.direction,
  });

  /// Prompt line shown above the options.
  String get promptFa => switch (mode) {
        GameMode.flag => 'این پرچم برای کدام کشور است؟',
        GameMode.currency => 'واحد پولِ ${answer.fa} کدام است؟',
        GameMode.capital => direction == CapitalDirection.capitalToCountry
            ? 'پایتختِ ${answer.capitalFa.isNotEmpty ? answer.capitalFa : answer.capital} مربوط به کدام کشور است؟'
            : 'پایتختِ ${answer.fa} کدام است؟',
        GameMode.map => 'این کدام کشور است؟',
        GameMode.neighbor => 'کدام کشور همسایهٔ ${answer.fa} نیست؟',
      };
}

/// Builds questions for the endless quiz.
class QuizRepository {
  QuizRepository(this._data, [Random? rng]) : _rng = rng ?? Random();
  final CountryData _data;
  final Random _rng;

  /// Regions selectable in the flag mode (per wireframe).
  static const regions = <String>['آسیا', 'اروپا', 'آفریقا', 'آمریکا', 'سایر'];

  /// Pool for a region. null/"کل جهان" => whole world.
  List<Country> _pool(GameMode mode, String? region) {
    var pool = _data.all;
    if (mode == GameMode.currency) {
      pool = pool.where((c) => c.hasCurrency).toList();
    } else if (mode == GameMode.capital) {
      pool = pool.where((c) => c.hasCapital).toList();
    } else if (mode == GameMode.map) {
      pool = pool.where((c) => c.hasMap).toList();
    } else if (mode == GameMode.neighbor) {
      pool = pool.where((c) => c.hasNeighbors).toList();
    }
    if (region != null && regions.contains(region)) {
      final filtered = pool.where((c) => c.region == region).toList();
      // need at least 4 for distinct options; otherwise fall back to world
      if (filtered.length >= 4) return filtered;
    }
    return pool;
  }

  /// Number of distinct countries available for a mode/region — the length of
  /// one full no-repeat round.
  int poolSize(GameMode mode, String? region) => _pool(mode, region).length;

  /// Builds the next question, drawing the answer from countries whose code is
  /// not in [exclude]. Returns null when every country has been used (round
  /// over). [exclude] holds the codes already asked this round.
  Question? next(
    GameMode mode, {
    String? region,
    Set<String>? exclude,
    CapitalDirection direction = CapitalDirection.countryToCapital,
  }) {
    final pool = _pool(mode, region);
    final remaining = exclude == null
        ? pool
        : pool.where((c) => !exclude.contains(c.code)).toList();
    if (remaining.isEmpty) return null;
    final answer = remaining[_rng.nextInt(remaining.length)];

    if (mode == GameMode.neighbor) {
      return _nextNeighbor(answer);
    }

    // distractors: 3 other countries from same pool, distinct labels
    final correctLabel = _label(mode, answer, direction);
    final used = <String>{correctLabel};
    final distractors = <Country>[];
    final shuffled = [...pool]..shuffle(_rng);
    for (final c in shuffled) {
      if (distractors.length == 3) break;
      if (c.code == answer.code) continue;
      final l = _label(mode, c, direction);
      if (used.contains(l)) continue;
      used.add(l);
      distractors.add(c);
    }

    final all = [answer, ...distractors]..shuffle(_rng);
    final options = all.map((c) => _label(mode, c, direction)).toList();
    return Question(
      mode: mode,
      answer: answer,
      options: options,
      correctIndex: all.indexWhere((c) => c.code == answer.code),
      correctAnswer: correctLabel,
      direction: mode == GameMode.capital ? direction : null,
    );
  }

  /// Builds an "odd one out" neighbor question: three real neighbors of
  /// [answer] plus one country that does NOT border it. The non-neighbor is the
  /// correct choice. Non-neighbor is drawn from the same region when possible so
  /// it stays plausible, falling back to the whole world otherwise.
  Question _nextNeighbor(Country answer) {
    final byCode = {for (final c in _data.all) c.code: c};

    // three real neighbors, distinct labels
    final neighbors = answer.borders
        .map((code) => byCode[code])
        .whereType<Country>()
        .toList()
      ..shuffle(_rng);
    final usedLabels = <String>{};
    final picked = <Country>[];
    for (final n in neighbors) {
      if (picked.length == 3) break;
      if (usedLabels.add(n.fa)) picked.add(n);
    }

    // non-neighbor: not the answer, not a neighbor, distinct label. Prefer same
    // region for a believable distractor.
    final excluded = {answer.code, ...answer.borders};
    bool eligible(Country c) =>
        !excluded.contains(c.code) && !usedLabels.contains(c.fa);
    final sameRegion =
        _data.all.where((c) => eligible(c) && c.region == answer.region).toList();
    final candidates = sameRegion.isNotEmpty
        ? sameRegion
        : _data.all.where(eligible).toList();
    final nonNeighbor = candidates[_rng.nextInt(candidates.length)];

    final all = [...picked, nonNeighbor]..shuffle(_rng);
    return Question(
      mode: GameMode.neighbor,
      answer: answer,
      options: all.map((c) => c.fa).toList(),
      correctIndex: all.indexWhere((c) => c.code == nonNeighbor.code),
      correctAnswer: nonNeighbor.fa,
    );
  }

  /// Option label for a country in a given mode. For the capital mode the
  /// direction decides whether options are capitals or country names.
  String _label(GameMode mode, Country c, CapitalDirection direction) =>
      switch (mode) {
        GameMode.flag || GameMode.map || GameMode.neighbor => c.fa,
        GameMode.currency => c.currencyFa.isNotEmpty ? c.currencyFa : c.currencyName,
        GameMode.capital => direction == CapitalDirection.capitalToCountry
            ? c.fa
            : (c.capitalFa.isNotEmpty ? c.capitalFa : c.capital),
      };
}
