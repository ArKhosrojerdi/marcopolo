import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/country.dart';
import 'data/quiz_repository.dart';
import 'state/ad_service.dart';
import 'state/game_controller.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget: ad init must never block or fail app startup.
  AdService.instance.initialize();
  final data = await CountryData.load();
  final prefs = await SharedPreferences.getInstance();
  final controller = GameController(QuizRepository(data), prefs);
  runApp(CountryQuizApp(controller: controller));
}

class CountryQuizApp extends StatelessWidget {
  const CountryQuizApp({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مارکوپولو',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      locale: const Locale('fa'),
      // Force RTL for the whole app.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: HomeScreen(controller: controller),
    );
  }
}
