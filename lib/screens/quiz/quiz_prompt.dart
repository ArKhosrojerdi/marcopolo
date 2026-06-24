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
