import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:country_quiz/data/country.dart';
import 'package:country_quiz/data/quiz_repository.dart';
import 'package:country_quiz/state/game_controller.dart';
import 'package:country_quiz/screens/quiz_screen.dart';

CountryData _fakeData() {
  Country c(String code, String fa, String region) => Country(
        code: code,
        fa: fa,
        en: code,
        capital: '$fa-cap',
        currencyName: '$fa-cur',
        currencySymbol: '¤',
        region: region,
      );
  final all = <Country>[];
  for (var i = 0; i < 8; i++) {
    all.add(c('as$i', 'کشور$i', 'آسیا'));
  }
  return CountryData.fromList(all);
}

Widget _wrap(GameController c) => MaterialApp(
      builder: (_, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: QuizScreen(controller: c),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('capital mode: correct answer increments streak & record',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    // seed=0 is deterministic; use capital mode (no flag SVG to load)
    final repo = QuizRepository(_fakeData(), Random(0));
    final c = GameController(repo, prefs)..start(GameMode.capital);
    await tester.pumpWidget(_wrap(c));

    expect(c.streak, 0);
    final q = c.question!;
    final correctText = q.options[q.correctIndex];

    await tester.tap(find.text(correctText).first);
    await tester.pumpAndSettle();

    expect(c.state, AnswerState.correct);
    expect(c.streak, 1);
    expect(c.record, 1);
    expect(find.text('آفرین! درست بود'), findsOneWidget);
    expect(prefs.getInt('streak_record_capital'), 1);

    // advance
    await tester.tap(find.text('سوال بعدی ‹'));
    await tester.pumpAndSettle();
    expect(c.answered, false);
  });

  testWidgets('wrong answer resets streak to 0 and shows correct answer',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final repo = QuizRepository(_fakeData(), Random(7));
    final c = GameController(repo, prefs)..start(GameMode.capital);
    await tester.pumpWidget(_wrap(c));

    final q = c.question!;
    final wrongIndex = (q.correctIndex + 1) % q.options.length;
    await tester.tap(find.text(q.options[wrongIndex]).first);
    await tester.pumpAndSettle();

    expect(c.state, AnswerState.wrong);
    expect(c.streak, 0);
    expect(find.textContaining('اشتباه شد'), findsOneWidget);
    expect(find.text('ادامه ‹'), findsOneWidget);
  });
}
