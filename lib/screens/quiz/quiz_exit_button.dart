import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/press_sink.dart';

/// Round sticker exit button in the quiz header — icon only, pops to the menu.
/// Same 44×44 circle as the back/mute buttons, with a close glyph.
class QuizExitButton extends StatelessWidget {
  const QuizExitButton({super.key, required this.onTap});
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
      child: const Icon(Icons.close, size: 24, color: AppColors.ink),
    );
  }
}
