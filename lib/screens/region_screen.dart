import 'package:flutter/material.dart';

import '../data/quiz_repository.dart';
import '../state/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker_card.dart';
import 'quiz_screen.dart';

/// Region (continent) selection — only for the flag mode (wireframe).
class RegionScreen extends StatelessWidget {
  const RegionScreen({super.key, required this.controller, required this.mode});
  final GameController controller;
  final GameMode mode;

  void _start(BuildContext context, String? region) {
    controller.start(mode, region: region);
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
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 10),
                      Text(
                        'بازی ${mode.titleFa}',
                        style: AppTheme.handSize(26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'منطقه را انتخاب کن:',
                    style: TextStyle(
                      fontFamily: AppTheme.sans,
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _RegionRow(
                    label: '🌍 کل جهان',
                    highlight: true,
                    onTap: () => _start(context, null),
                  ),
                  for (final r in QuizRepository.regions) ...[
                    const SizedBox(height: 13),
                    _RegionRow(label: r, onTap: () => _start(context, r)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionRow extends StatelessWidget {
  const _RegionRow({
    required this.label,
    required this.onTap,
    this.highlight = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      onTap: onTap,
      background: highlight ? AppColors.highlight : AppColors.card,
      borderWidth: highlight ? 1.8 : 1.6,
      padding: EdgeInsets.symmetric(vertical: highlight ? 16 : 14),
      child: Center(
        child: Text(label, style: AppTheme.handSize(highlight ? 26 : 24)),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1.5),
          shape: BoxShape.circle,
        ),
        // RTL: back chevron points left ("‹")
        child: const Text('‹', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
