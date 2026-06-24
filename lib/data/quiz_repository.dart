import 'dart:math';
import 'country.dart';

enum GameMode { flag, currency, map, capital }

extension GameModeInfo on GameMode {
  String get titleFa => switch (this) {
        GameMode.flag => 'پرچم',
        GameMode.currency => 'واحد پول',
        GameMode.map => 'نقشه کشور',
        GameMode.capital => 'پایتخت',
      };

  /// Whether this mode has a region (continent) selection step. Only flag.
  bool get hasRegionStep => this == GameMode.flag;
  bool get isAvailable => this != GameMode.map;
}

/// A single generated quiz question.
class Question {
  final GameMode mode;
  final Country answer;
  final List<String> options; // option labels (shuffled)
  final int correctIndex;

  const Question({
    required this.mode,
    required this.answer,
    required this.options,
    required this.correctIndex,
  });

  /// Prompt line shown above the options.
  String get promptFa => switch (mode) {
        GameMode.flag => 'این پرچم برای کدام کشور است؟',
        GameMode.currency => 'واحد پولِ کدام کشور است؟',
        GameMode.capital => 'پایتختِ ${answer.fa} کدام است؟',
        GameMode.map => 'این کدام کشور است؟',
      };
}

/// Builds questions for the endless quiz.
class QuizRepository {
  QuizRepository(this._data, [Random? rng]) : _rng = rng ?? Random();
  final CountryData _data;
  final Random _rng;

  /// Regions selectable in the flag mode (per wireframe).
  static const regions = <String>['آسیا', 'اروپا', 'آفریقا', 'آمریکا'];

  /// Pool for a region. null/"کل جهان" => whole world.
  List<Country> _pool(GameMode mode, String? region) {
    var pool = _data.all;
    if (mode == GameMode.currency) {
      pool = pool.where((c) => c.hasCurrency).toList();
    } else if (mode == GameMode.capital) {
      pool = pool.where((c) => c.hasCapital).toList();
    }
    if (region != null && regions.contains(region)) {
      final filtered = pool.where((c) => c.region == region).toList();
      // need at least 4 for distinct options; otherwise fall back to world
      if (filtered.length >= 4) return filtered;
    }
    return pool;
  }

  Question next(GameMode mode, {String? region, Country? avoid}) {
    final pool = _pool(mode, region);
    Country answer;
    do {
      answer = pool[_rng.nextInt(pool.length)];
    } while (avoid != null && answer.code == avoid.code && pool.length > 1);

    // distractors: 3 other countries from same pool, distinct labels
    final correctLabel = _label(mode, answer);
    final used = <String>{correctLabel};
    final distractors = <Country>[];
    final shuffled = [...pool]..shuffle(_rng);
    for (final c in shuffled) {
      if (distractors.length == 3) break;
      if (c.code == answer.code) continue;
      final l = _label(mode, c);
      if (used.contains(l)) continue;
      used.add(l);
      distractors.add(c);
    }

    final all = [answer, ...distractors]..shuffle(_rng);
    final options = all.map((c) => _label(mode, c)).toList();
    return Question(
      mode: mode,
      answer: answer,
      options: options,
      correctIndex: all.indexWhere((c) => c.code == answer.code),
    );
  }

  /// Option label for a country in a given mode.
  String _label(GameMode mode, Country c) => switch (mode) {
        GameMode.flag || GameMode.currency || GameMode.map => c.fa,
        GameMode.capital => c.capital,
      };
}
