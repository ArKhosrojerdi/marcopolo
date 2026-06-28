import 'package:flutter/material.dart';

import '../../data/quiz_repository.dart';
import '../../data/seasons.dart';
import '../../state/level_progress.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_button.dart';
import '../../widgets/sticker_card.dart';
import 'level_grid_screen.dart';

/// Season list for the "مراحل" (levels) game mode. Each row opens that season's
/// level grid and shows how many of its levels have been played.
class SeasonsScreen extends StatelessWidget {
  const SeasonsScreen({
    super.key,
    required this.repo,
    required this.progress,
  });

  final QuizRepository repo;
  final LevelProgress progress;

  void _open(BuildContext context, SeasonDef season) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LevelGridScreen(
          season: season,
          repo: repo,
          progress: progress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListenableBuilder(
              listenable: progress,
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
                        Text('مراحل', style: AppTheme.handSize(28)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'یک فصل را انتخاب کن:',
                      style: TextStyle(
                        fontFamily: AppTheme.sans,
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (final season in SeasonCatalog.seasons) ...[
                      _SeasonRow(
                        season: season,
                        played: progress.playedInSeason(season),
                        onTap: () => _open(context, season),
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

class _SeasonRow extends StatelessWidget {
  const _SeasonRow({
    required this.season,
    required this.played,
    required this.onTap,
  });

  final SeasonDef season;
  final int played;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = season.levels.length;
    return StickerCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      child: Row(
        children: [
          Text(season.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(season.titleFa, style: AppTheme.handSize(22)),
                const SizedBox(height: 2),
                Text(
                  '${toPersianDigits(played)} از ${toPersianDigits(total)} مرحله',
                  style: const TextStyle(
                    fontFamily: AppTheme.sans,
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const Text('›', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }
}
