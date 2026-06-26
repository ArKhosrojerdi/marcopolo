import 'package:flutter/material.dart';

import '../data/quiz_repository.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/back_button.dart';
import '../widgets/sticker_card.dart';
import 'region_screen.dart';

/// Direction selection — only for the capital mode. Lets the player choose
/// whether they're shown the country (and pick the capital) or shown the
/// capital (and pick the country).
class CapitalDirectionScreen extends StatelessWidget {
  const CapitalDirectionScreen({
    super.key,
    required this.controller,
    required this.mode,
  });
  final GameController controller;
  final GameMode mode;

  void _start(BuildContext context, CapitalDirection direction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegionScreen(
          controller: controller,
          mode: mode,
          direction: direction,
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
                    'حالت بازی را انتخاب کن:',
                    style: TextStyle(
                      fontFamily: AppTheme.sans,
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DirectionRow(
                    emoji: '🏳️',
                    title: 'کشور ← پایتخت',
                    subtitle: 'کشور را می‌بینی، پایتختش را پیدا کن',
                    highlight: true,
                    onTap: () =>
                        _start(context, CapitalDirection.countryToCapital),
                  ),
                  const SizedBox(height: 13),
                  _DirectionRow(
                    emoji: '🏛️',
                    title: 'پایتخت ← کشور',
                    subtitle: 'پایتخت را می‌بینی، کشورش را پیدا کن',
                    onTap: () =>
                        _start(context, CapitalDirection.capitalToCountry),
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

class _DirectionRow extends StatelessWidget {
  const _DirectionRow({
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
