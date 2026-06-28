import 'package:flutter/material.dart';

import '../../data/quiz_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/flag_image.dart';
import '../../widgets/map_image.dart';
import 'panel.dart';

/// The prompt block above the options — varies per mode (flag/map image, or a
/// framed [Panel] for currency / capital / neighbor).
class QuizPrompt extends StatelessWidget {
  const QuizPrompt({super.key, required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    // Attribute questions (e.g. color levels) carry their own prompt text and
    // have no image to show — render the override as a framed text panel.
    if (question.promptOverride != null) {
      return Panel(
        children: [
          Text(
            question.promptOverride!,
            textAlign: TextAlign.center,
            style: AppTheme.handSize(28),
          ),
        ],
      );
    }
    switch (question.mode) {
      case GameMode.flag:
        return FlagImage(assetPath: question.answer.flagAsset);
      case GameMode.map:
        return MapImage(assetPath: question.answer.mapAsset);
      case GameMode.currency:
        return Panel(
          children: [
            const Text(
              'واحد پولِ',
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(question.answer.fa, style: AppTheme.handSize(40)),
            const SizedBox(height: 4),
            const Text(
              'کدام است؟',
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        );
      case GameMode.neighbor:
        if (question.neighborLabels.isNotEmpty) {
          return Panel(
            children: [
              const Text(
                'این‌ها همسایه‌های کدام کشورند؟',
                style: TextStyle(
                  fontFamily: AppTheme.sans,
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n in question.neighborLabels)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.ink, width: 1.4),
                      ),
                      child: Text(n, style: AppTheme.handSize(20)),
                    ),
                ],
              ),
            ],
          );
        }
        return Panel(
          children: [
            const Text(
              'کدام کشور همسایهٔ',
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(question.answer.fa, style: AppTheme.handSize(40)),
            const SizedBox(height: 4),
            const Text(
              'نیست؟',
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        );
      case GameMode.capital:
        final toCountry =
            question.direction == CapitalDirection.capitalToCountry;
        return Panel(
          children: [
            const Text(
              'پایتختِ',
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              toCountry
                  ? (question.answer.capitalFa.isNotEmpty
                      ? question.answer.capitalFa
                      : question.answer.capital)
                  : question.answer.fa,
              style: AppTheme.handSize(40),
            ),
            const SizedBox(height: 4),
            Text(
              toCountry ? 'مربوط به کدام کشور است؟' : 'کدام است؟',
              style: const TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        );
    }
  }
}
