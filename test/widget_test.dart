import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

import 'package:country_quiz/data/country.dart';
import 'package:country_quiz/data/quiz_repository.dart';

CountryData _fakeData() {
  Country c(String code, String fa, String region) => Country(
        code: code,
        fa: fa,
        en: code.toUpperCase(),
        capital: '$fa-cap',
        currencyName: '$fa-cur',
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
    final q = repo.next(GameMode.flag, region: 'آسیا');
    expect(q.options.length, 4);
    expect(q.options.toSet().length, 4); // distinct
    expect(q.options[q.correctIndex], q.answer.fa);
  });

  test('capital options are capital cities', () {
    final repo = QuizRepository(_fakeData(), Random(2));
    final q = repo.next(GameMode.capital);
    expect(q.options[q.correctIndex], q.answer.capital);
  });

  test('region filter keeps answers in region when pool large enough', () {
    final repo = QuizRepository(_fakeData(), Random(3));
    for (var i = 0; i < 20; i++) {
      final q = repo.next(GameMode.flag, region: 'اروپا');
      expect(q.answer.region, 'اروپا');
    }
  });
}
