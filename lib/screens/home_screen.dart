import 'package:flutter/material.dart';

import '../data/quiz_repository.dart';
import '../state/game_controller.dart';
import '../state/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mute_button.dart';
import '../widgets/sticker_card.dart';
import 'capital_direction_screen.dart';
import 'quiz_screen.dart';
import 'region_screen.dart';

/// Home — 2x2 mode grid (wireframe Variant A).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});
  final GameController controller;

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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ListenableBuilder(
                      listenable: SoundService.instance,
                      builder: (context, _) => MuteStickerButton(
                        muted: SoundService.instance.muted,
                        onTap: SoundService.instance.toggleMute,
                      ),
                    ),
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
                  Expanded(
                    child: ListenableBuilder(
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
    GameMode.neighbor => '🧭',
  };

  @override
  Widget build(BuildContext context) {
    // Post-it "page marker" tab pokes out the top-right, sitting *behind* the
    // card so it reads like a bookmark stuck to the back of the sticker.
    const tabHeight = 26.0;
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // Tab — painted first so the card overlaps its lower edge.
        Positioned(top: 0, right: 12, child: _RecordTab(record: record)),
        // Card fills the grid cell below the tab.
        Positioned.fill(
          top: tabHeight - 6,
          child: StickerCard(
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
          ),
        ),
      ],
    );
  }
}

/// Small post-it tab showing the record number, tucked behind a [_ModeCard].
class _RecordTab extends StatelessWidget {
  const _RecordTab({required this.record});
  final int record;

  @override
  Widget build(BuildContext context) {
    return Container(
      // extra bottom padding tucks under the card's top edge
      padding: const EdgeInsets.fromLTRB(10, 3, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.postit,
        border: Border.all(color: AppColors.postitBorder, width: 1.6),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
      ),
      child: Text(
        toPersianDigits(record),
        style: const TextStyle(
          fontFamily: AppTheme.sans,
          fontSize: 12,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
