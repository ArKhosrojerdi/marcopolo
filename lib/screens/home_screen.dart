import 'package:flutter/material.dart';

import '../data/quiz_repository.dart';
import '../state/game_controller.dart';
import '../state/level_progress.dart';
import '../state/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mute_button.dart';
import '../widgets/press_sink.dart';
import '../widgets/sticker_card.dart';
import 'achievements_screen.dart';
import 'capital_direction_screen.dart';
import 'difficulty_screen.dart';
import 'levels/seasons_screen.dart';
import 'region_screen.dart';

/// Home — 2x2 mode grid (wireframe Variant A).
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.progress,
  });
  final GameController controller;
  final LevelProgress progress;

  void _pick(BuildContext context, GameMode mode) {
    if (mode.hasRegionStep) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegionScreen(controller: controller, mode: mode),
        ),
      );
    } else if (mode.hasDirectionStep) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CapitalDirectionScreen(controller: controller, mode: mode),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DifficultyScreen(controller: controller, mode: mode),
        ),
      );
    }
  }

  void _openSeasons(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SeasonsScreen(repo: controller.repo, progress: progress),
      ),
    );
  }

  void _openAchievements(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AchievementsScreen(
          controller: controller,
          progress: progress,
          repo: controller.repo,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ListenableBuilder(
                        listenable: SoundService.instance,
                        builder: (context, _) => MuteStickerButton(
                          muted: SoundService.instance.muted,
                          onTap: SoundService.instance.toggleMute,
                        ),
                      ),
                      _AchievementsButton(
                        onTap: () => _openAchievements(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                  _LevelsCard(onTap: () => _openSeasons(context)),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.15,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: [
                        for (final mode in GameMode.values)
                          _ModeCard(
                            mode: mode,
                            onTap: () => _pick(context, mode),
                          ),
                      ],
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

/// Full-width entry into the levels ("مراحل") game mode, below the mode grid.
class _LevelsCard extends StatelessWidget {
  const _LevelsCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      onTap: onTap,
      background: AppColors.highlight,
      borderWidth: 1.8,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧩', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Text('مراحل', style: AppTheme.handSize(26)),
        ],
      ),
    );
  }
}

/// Trophy button in the home header that opens the achievements screen.
class _AchievementsButton extends StatelessWidget {
  const _AchievementsButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressSink(
      onTap: onTap,
      shape: BoxShape.circle,
      borderWidth: 1.8,
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: const Text('🏆', style: TextStyle(fontSize: 20)),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.onTap,
  });
  final GameMode mode;
  final VoidCallback onTap;

  String get _emoji => switch (mode) {
    GameMode.flag => '🚩',
    GameMode.currency => '💰',
    GameMode.map => '🗺️',
    GameMode.capital => '🏛️',
    GameMode.neighbor => '🧭',
  };

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text(mode.titleFa, style: AppTheme.handSize(24)),
        ],
      ),
    );
  }
}
