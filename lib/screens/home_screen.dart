import 'package:flutter/material.dart';

import '../data/quiz_repository.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker_card.dart';
import '../widgets/streak_badge.dart';
import 'coming_soon_screen.dart';
import 'quiz_screen.dart';
import 'region_screen.dart';

/// Home — 2x2 mode grid (wireframe Variant A).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});
  final GameController controller;

  void _pick(BuildContext context, GameMode mode) {
    if (!mode.isAvailable) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ComingSoonScreen()));
      return;
    }
    if (mode.hasRegionStep) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegionScreen(controller: controller, mode: mode),
        ),
      );
    } else {
      controller.start(mode);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuizScreen(controller: controller)),
      );
    }
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.ink, width: 1.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('☰', style: TextStyle(fontSize: 14)),
                      ),
                      ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) => StreakBadge(
                          label: 'رکورد',
                          value: toPersianDigits(controller.bestRecord),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('مارکوپولو', style: AppTheme.handSize(38)),
                  const SizedBox(height: 6),
                  const Text(
                    'یک حالت بازی را انتخاب کن',
                    style: TextStyle(
                      fontFamily: AppTheme.sans,
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) => GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.05,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          for (final mode in GameMode.values)
                            _ModeCard(
                              mode: mode,
                              record: controller.recordFor(mode),
                              onTap: () => _pick(context, mode),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.record,
    required this.onTap,
  });
  final GameMode mode;
  final int record;
  final VoidCallback onTap;

  String get _emoji => switch (mode) {
    GameMode.flag => '🚩',
    GameMode.currency => '💰',
    GameMode.map => '🗺️',
    GameMode.capital => '🏛️',
  };

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text(mode.titleFa, style: AppTheme.handSize(24)),
          if (!mode.isAvailable)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'به‌زودی',
                style: TextStyle(
                  fontFamily: AppTheme.sans,
                  fontSize: 10,
                  color: AppColors.faint,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'رکورد: ${toPersianDigits(record)}',
                style: const TextStyle(
                  fontFamily: AppTheme.sans,
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
