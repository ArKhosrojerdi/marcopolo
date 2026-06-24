import 'package:flutter/material.dart';

import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/press_sink.dart';
import 'panel.dart';

/// Round-complete screen: score summary + best record, then Play again
/// (primary) and Exit. Shown once the whole pool has been walked.
class QuizComplete extends StatelessWidget {
  const QuizComplete({
    super.key,
    required this.controller,
    required this.onExit,
  });
  final GameController controller;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final correct = toPersianDigits(controller.correct);
    final total = toPersianDigits(controller.total);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تمام شد!',
            textAlign: TextAlign.center,
            style: AppTheme.handSize(40),
          ),
          const SizedBox(height: 18),
          Panel(
            children: [
              Text(
                '$correct از $total درست',
                style: AppTheme.handSize(28, color: AppColors.correct),
              ),
              const SizedBox(height: 8),
              Text(
                'رکورد: ${toPersianDigits(controller.record)}',
                style: const TextStyle(
                  fontFamily: AppTheme.sans,
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _ActionButton(
            label: 'شروع مجدد',
            primary: true,
            onTap: controller.playAgain,
          ),
          const SizedBox(height: 12),
          _ActionButton(label: 'خروج', primary: false, onTap: onExit),
        ],
      ),
    );
  }
}

/// Full-width sticker button. [primary] fills with the ink color (Play again);
/// otherwise it's an outline (Exit).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressSink(
      onTap: onTap,
      borderRadius: 24,
      background: primary ? AppColors.ink : AppColors.card,
      borderWidth: 1.6,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.sans,
          fontSize: 15,
          color: primary ? AppColors.card : AppColors.ink,
        ),
      ),
    );
  }
}
