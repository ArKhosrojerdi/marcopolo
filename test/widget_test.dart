import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

import 'package:marcopolo/data/country.dart';
import 'package:marcopolo/data/quiz_repository.dart';

CountryData _fakeData() {
  Country c(String code, String fa, String region) => Country(
        code: code,
        fa: fa,
        en: code.toUpperCase(),
        capital: '$fa-cap',
        currencyName: '$fa-cur',
        currencyFa: '$fa-cur-fa',
        currencySymbol: '¤',
        region: region,
      );
  final all = <Country>[];
  for (final r in ['آسیا', 'اروپا', 'آفریقا', 'آمریکا']) {
    for (var i = 0; i < 6; i++) {
      all.add(c('$r$i', '$r$i', r));
    }
  }
  return CountryData.fromList(all);
}

void main() {
  test('flag question has 4 distinct options including the answer', () {
    final repo = QuizRepository(_fakeData(), Random(1));
    final q = repo.next(GameMode.flag, region: 'آسیا')!;
    expect(q.options.length, 4);
    expect(q.options.toSet().length, 4); // distinct
    expect(q.options[q.correctIndex], q.answer.fa);
  });

  test('capital options are capital cities', () {
    final repo = QuizRepository(_fakeData(), Random(2));
    final q = repo.next(GameMode.capital)!;
    expect(q.options[q.correctIndex], q.answer.capital);
    expect(q.direction, CapitalDirection.countryToCapital);
  });

  test('capital→country direction: options are country names', () {
    final repo = QuizRepository(_fakeData(), Random(2));
    final q = repo.next(
      GameMode.capital,
      direction: CapitalDirection.capitalToCountry,
    )!;
    expect(q.options.length, 4);
    expect(q.options.toSet().length, 4); // distinct
    expect(q.options[q.correctIndex], q.answer.fa);
    expect(q.direction, CapitalDirection.capitalToCountry);
    expect(q.promptFa, contains(q.answer.capital));
  });

  test('region filter keeps answers in region when pool large enough', () {
    final repo = QuizRepository(_fakeData(), Random(3));
    for (var i = 0; i < 20; i++) {
      final q = repo.next(GameMode.flag, region: 'اروپا')!;
      expect(q.answer.region, 'اروپا');
    }
  });

  test('neighbor: correct option is the non-neighbor, others are neighbors', () {
    // a (≥3 neighbors) borders b,c,d; e..h are non-neighbors in same region.
    Country c(String code, List<String> borders) => Country(
          code: code,
          fa: code,
          en: code.toUpperCase(),
          capital: '$code-cap',
          currencyName: '',
          currencyFa: '',
          currencySymbol: '',
          region: 'آسیا',
          borders: borders,
        );
    final data = CountryData.fromList([
      c('a', ['b', 'c', 'd']),
      c('b', ['a']),
      c('c', ['a']),
      c('d', ['a']),
      c('e', []),
      c('f', []),
      c('g', []),
      c('h', []),
    ]);
    final repo = QuizRepository(data, Random(7));
    for (var i = 0; i < 30; i++) {
      final q = repo.next(GameMode.neighbor)!;
      expect(q.options.length, 4);
      expect(q.options.toSet().length, 4); // distinct
      expect(q.answer.code, 'a'); // only country with >=3 neighbors
      final correct = q.options[q.correctIndex];
      expect(q.answer.borders, isNot(contains(correct))); // truly not a neighbor
      for (var j = 0; j < q.options.length; j++) {
        if (j == q.correctIndex) continue;
        expect(q.answer.borders, contains(q.options[j])); // others are neighbors
      }
    }
  });

  test('neighbor hard: correct option is the bordered country, prompt lists '
      'its neighbors', () {
    Country c(String code, List<String> borders) => Country(
          code: code,
          fa: code,
          en: code.toUpperCase(),
          capital: '$code-cap',
          currencyName: '',
          currencyFa: '',
          currencySymbol: '',
          region: 'آسیا',
          borders: borders,
        );
    final data = CountryData.fromList([
      c('a', ['b', 'c', 'd']),
      c('b', ['a']),
      c('c', ['a']),
      c('d', ['a']),
      c('e', []),
      c('f', []),
      c('g', []),
      c('h', []),
    ]);
    final repo = QuizRepository(data, Random(7));
    for (var i = 0; i < 30; i++) {
      final q = repo.next(GameMode.neighbor, difficulty: GameDifficulty.hard)!;
      expect(q.options.length, 4);
      expect(q.options.toSet().length, 4); // distinct
      expect(q.answer.code, 'a'); // only country with >=3 neighbors
      // correct option is the answer country itself
      expect(q.options[q.correctIndex], 'a');
      expect(q.correctAnswer, 'a');
      // prompt shows all neighbors of the answer
      expect(q.neighborLabels.toSet(), {'b', 'c', 'd'});
      // no shown neighbor appears among the options
      for (final n in q.neighborLabels) {
        expect(q.options, isNot(contains(n)));
      }
    }
  });
}
