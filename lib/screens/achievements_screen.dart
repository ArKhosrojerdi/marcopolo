import 'package:flutter/material.dart';

import '../data/quiz_repository.dart';
import '../state/game_controller.dart';
import '../state/level_progress.dart';
import '../theme/app_theme.dart';
import '../widgets/back_button.dart';
import 'quiz/panel.dart';

/// Medal thresholds per game mode (best streak/record). The final "all" tier is
/// resolved per mode from the pool size, so it represents clearing the whole set.
const _medalTiers = <int>[5, 10, 25, 50, 75, 100, 150];

/// Achievements: a medal track per game mode driven by best records, plus the
/// total count of 3-star levels.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({
    super.key,
    required this.controller,
    required this.progress,
    required this.repo,
  });

  final GameController controller;
  final LevelProgress progress;
  final QuizRepository repo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListenableBuilder(
              listenable: Listenable.merge([controller, progress]),
              builder: (context, _) => SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        BackStickerButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 10),
                        Text('دستاوردها', style: AppTheme.handSize(28)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ThreeStarPanel(count: progress.threeStarCount),
                    const SizedBox(height: 18),
                    for (final mode in GameMode.values) ...[
                      _ModeMedals(
                        mode: mode,
                        record: controller.recordFor(mode),
                        poolSize: repo.poolSize(mode, null),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreeStarPanel extends StatelessWidget {
  const _ThreeStarPanel({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Panel(
      children: [
        const Text('⭐⭐⭐', style: TextStyle(fontSize: 26)),
        const SizedBox(height: 6),
        Text(
          'مراحل سه‌ستاره: ${toPersianDigits(count)}',
          style: AppTheme.handSize(22),
        ),
      ],
    );
  }
}

/// One mode's medal track: a label + a row of tier medals, earned ones gold.
class _ModeMedals extends StatelessWidget {
  const _ModeMedals({
    required this.mode,
    required this.record,
    required this.poolSize,
  });

  final GameMode mode;
  final int record;
  final int poolSize;

  /// Tier targets: the fixed ladder, then "all" (the pool size) appended if it
  /// is larger than the last fixed tier.
  List<int> get _tiers {
    final tiers = [..._medalTiers.where((t) => t < poolSize)];
    if (poolSize > 0) tiers.add(poolSize);
    return tiers;
  }

  @override
  Widget build(BuildContext context) {
    final tiers = _tiers;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: AppTheme.sticker(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(mode.titleFa, style: AppTheme.handSize(20)),
              Text(
                'رکورد: ${toPersianDigits(record)}',
                style: const TextStyle(
                  fontFamily: AppTheme.sans,
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tier in tiers)
                _Medal(target: tier, earned: record >= tier, isAll: tier == poolSize),
            ],
          ),
        ],
      ),
    );
  }
}

class _Medal extends StatelessWidget {
  const _Medal({
    required this.target,
    required this.earned,
    required this.isAll,
  });

  final int target;
  final bool earned;
  final bool isAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: earned ? 1 : 0.3,
          child: Text(
            earned ? '🏅' : '⚪',
            style: const TextStyle(fontSize: 24),
          ),
        ),
        Text(
          isAll ? 'همه' : toPersianDigits(target),
          style: TextStyle(
            fontFamily: AppTheme.sans,
            fontSize: 10,
            color: earned ? AppColors.ink : AppColors.muted,
          ),
        ),
      ],
    );
  }
}
