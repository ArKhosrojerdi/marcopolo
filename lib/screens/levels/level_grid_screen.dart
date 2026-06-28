import 'package:flutter/material.dart';

import '../../data/quiz_repository.dart';
import '../../data/seasons.dart';
import '../../state/level_progress.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_button.dart';
import '../../widgets/press_sink.dart';
import 'level_play_screen.dart';

/// Grid of level tiles for one season. Locked tiles are dimmed and inert;
/// unlocked tiles show their best-star result and open the level on tap.
class LevelGridScreen extends StatelessWidget {
  const LevelGridScreen({
    super.key,
    required this.season,
    required this.repo,
    required this.progress,
  });

  final SeasonDef season;
  final QuizRepository repo;
  final LevelProgress progress;

  void _open(BuildContext context, LevelDef level) {
    // Progress is a ChangeNotifier; the ListenableBuilder below rebuilds the
    // grid when the level result lands, so no manual refresh on return needed.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LevelPlayScreen(
          level: level,
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListenableBuilder(
              listenable: progress,
              builder: (context, _) => Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    child: Row(
                      children: [
                        BackStickerButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${season.emoji} ${season.titleFa}',
                          style: AppTheme.handSize(24),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 4,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      children: [
                        for (var i = 0; i < season.levels.length; i++)
                          _LevelTile(
                            number: i + 1,
                            unlocked:
                                progress.isUnlocked(season.levels[i].globalIndex),
                            stars: progress.starsFor(season.levels[i].globalIndex),
                            onTap: () => _open(context, season.levels[i]),
                          ),
                      ],
                    ),
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

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.number,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });

  final int number;
  final bool unlocked;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!unlocked) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.dimBorder, width: 1.6),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Text('🔒', style: TextStyle(fontSize: 22)),
      );
    }
    return PressSink(
      onTap: onTap,
      borderRadius: 8,
      borderWidth: 1.8,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(toPersianDigits(number), style: AppTheme.handSize(22)),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final earned = i < stars;
              const star = Text('⭐', style: TextStyle(fontSize: 14));
              if (earned) return star;
              // Filled star, drained of color: desaturate then dim so it
              // reads as an empty slot without changing the glyph.
              return Opacity(
                opacity: 0.45,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0, //
                    0.2126, 0.7152, 0.0722, 0, 0, //
                    0.2126, 0.7152, 0.0722, 0, 0, //
                    0, 0, 0, 1, 0, //
                  ]),
                  child: star,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
