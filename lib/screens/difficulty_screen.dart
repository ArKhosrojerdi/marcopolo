import 'package:flutter/material.dart';

import '../data/quiz_repository.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/back_button.dart';
import '../widgets/sticker_card.dart';
import 'quiz_screen.dart';

/// Difficulty selection — always the final step before the quiz starts.
class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({
    super.key,
    required this.controller,
    required this.mode,
    this.region,
    this.direction = CapitalDirection.countryToCapital,
  });

  final GameController controller;
  final GameMode mode;
  final String? region;
  final CapitalDirection direction;

  void _start(BuildContext context, GameDifficulty difficulty) {
    controller.start(mode, region: region, direction: direction, difficulty: difficulty);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizScreen(controller: controller)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      BackStickerButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 10),
                      Text(
                        'بازی ${mode.titleFa}',
                        style: AppTheme.handSize(26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'سطح دشواری را انتخاب کن:',
                    style: TextStyle(
                      fontFamily: AppTheme.sans,
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DifficultyRow(
                    emoji: '🟢',
                    title: 'معمولی',
                    subtitle: 'چهار گزینه داری — یکی را انتخاب کن',
                    highlight: true,
                    onTap: () => _start(context, GameDifficulty.normal),
                  ),
                  const SizedBox(height: 13),
                  _DifficultyRow(
                    emoji: '🔴',
                    title: 'سخت',
                    subtitle: mode == GameMode.neighbor
                        ? 'همهٔ همسایه‌ها را می‌بینی — کشور را پیدا کن'
                        : 'جواب را خودت تایپ کن — بدون گزینه',
                    onTap: () => _start(context, GameDifficulty.hard),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      onTap: onTap,
      background: highlight ? AppColors.highlight : AppColors.card,
      borderWidth: highlight ? 1.8 : 1.6,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.handSize(22)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: AppTheme.sans,
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
