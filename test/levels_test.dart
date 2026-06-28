import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:math';

import 'package:marcopolo/data/country.dart';
import 'package:marcopolo/data/flag_colors.dart';
import 'package:marcopolo/data/quiz_repository.dart';
import 'package:marcopolo/data/seasons.dart';
import 'package:marcopolo/state/level_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LevelProgress> freshProgress() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return LevelProgress(prefs);
  }

  group('SeasonCatalog', () {
    test('global indexes are 1-based, contiguous, and unique', () {
      final indexes = SeasonCatalog.allLevels.map((l) => l.globalIndex).toList();
      expect(indexes.first, 1);
      expect(indexes, List.generate(indexes.length, (i) => i + 1));
      expect(indexes.toSet().length, indexes.length);
    });

    test('has at least the flag and capital seasons', () {
      final ids = SeasonCatalog.seasons.map((s) => s.id).toSet();
      expect(ids, containsAll(<String>['flags', 'capitals']));
    });
  });

  group('colorQuestion', () {
    // Country set covering every stub code, so the generator has a full pool.
    CountryData stubData() {
      Country c(String code) => Country(
            code: code,
            fa: 'نام-$code',
            en: code,
            capital: '',
            currencyName: '',
            currencyFa: '',
            currencySymbol: '',
            region: 'سایر',
          );
      return CountryData.fromList(
        [for (final code in kFlagColorCodes) c(code)],
      );
    }

    test('answer flag has the asked color; distractors do not', () {
      final repo = QuizRepository(stubData(), Random(1));
      for (var i = 0; i < 50; i++) {
        final q = repo.colorQuestion();
        expect(q, isNotNull);
        // Recover the asked color from the prompt text.
        final color = FlagColor.values
            .firstWhere((col) => q!.promptOverride!.contains(col.fa));
        // Map each option label back to its country code.
        for (var j = 0; j < q!.options.length; j++) {
          final code = kFlagColorCodes.firstWhere(
            (c) => 'نام-$c' == q.options[j],
          );
          final has = flagHasColor(code, color);
          expect(has, j == q.correctIndex);
        }
      }
    });

    test('returns null when no country has color data', () {
      final repo = QuizRepository(
        CountryData.fromList(const []),
        Random(1),
      );
      expect(repo.colorQuestion(), isNull);
    });
  });

  group('seeded draw (fixed level question set)', () {
    CountryData manyData() {
      Country c(int i) => Country(
            code: 'c$i',
            fa: 'نام$i',
            en: 'c$i',
            capital: '',
            currencyName: '',
            currencyFa: '',
            currencySymbol: '',
            region: 'سایر',
          );
      return CountryData.fromList([for (var i = 0; i < 30; i++) c(i)]);
    }

    List<String> drawCodes(CountryData data, int seed, int n) {
      final repo = QuizRepository(data, Random(999)); // instance rng differs
      final rng = Random(seed);
      final seen = <String>{};
      final codes = <String>[];
      for (var i = 0; i < n; i++) {
        final q = repo.next(GameMode.flag, exclude: seen, rng: rng)!;
        seen.add(q.answer.code);
        codes.add(q.answer.code);
      }
      return codes;
    }

    test('same seed yields the same answer set & order', () {
      final data = manyData();
      expect(drawCodes(data, 7, 10), equals(drawCodes(data, 7, 10)));
    });

    test('different seeds generally differ', () {
      final data = manyData();
      expect(drawCodes(data, 1, 10), isNot(equals(drawCodes(data, 2, 10))));
    });
  });

  group('LevelProgress', () {
    test('only the first level is unlocked initially', () async {
      final p = await freshProgress();
      expect(p.isUnlocked(1), isTrue);
      expect(p.isUnlocked(2), isFalse);
    });

    test('passing a level unlocks the next and records best stars', () async {
      final p = await freshProgress();
      await p.recordResult(1, 2, passed: true);
      expect(p.hasPlayed(1), isTrue);
      expect(p.hasPassed(1), isTrue);
      expect(p.isUnlocked(2), isTrue);
      expect(p.starsFor(1), 2);
    });

    test('failing a level does NOT unlock the next', () async {
      final p = await freshProgress();
      await p.recordResult(1, 0, passed: false);
      expect(p.hasPlayed(1), isTrue);
      expect(p.hasPassed(1), isFalse);
      expect(p.isUnlocked(2), isFalse);
      expect(p.starsFor(1), 0);
    });

    test('a later pass unlocks after an earlier fail', () async {
      final p = await freshProgress();
      await p.recordResult(1, 0, passed: false);
      expect(p.isUnlocked(2), isFalse);
      await p.recordResult(1, 3, passed: true);
      expect(p.isUnlocked(2), isTrue);
      expect(p.starsFor(1), 3);
    });

    test('best stars are kept, never lowered', () async {
      final p = await freshProgress();
      await p.recordResult(1, 3, passed: true);
      await p.recordResult(1, 1, passed: true);
      expect(p.starsFor(1), 3);
    });

    test('derived counters reflect played and three-star levels', () async {
      final p = await freshProgress();
      await p.recordResult(1, 3, passed: true);
      await p.recordResult(2, 1, passed: true);
      expect(p.playedCount, 2);
      expect(p.threeStarCount, 1);
    });
  });
}
