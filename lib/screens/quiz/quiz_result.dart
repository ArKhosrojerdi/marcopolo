import 'package:flutter/material.dart';

import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/press_sink.dart';

/// Result line + next button (correct => green/«سوال بعدی», wrong => red/«ادامه»).
///
/// Mounts fresh on each answer, so it plays an entrance every time: the
/// message fades + drops in, then the next button springs up a beat later.
class QuizResult extends StatefulWidget {
  const QuizResult({super.key, required this.controller});
  final GameController controller;

  @override
  State<QuizResult> createState() => _QuizResultState();
}

class _QuizResultState extends State<QuizResult>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  // Message: first half of the timeline. Button: staggered second half.
  late final Animation<double> _btnScale = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.45, 1.0, curve: Curves.elasticOut),
  );
  late final Animation<double> _btnFade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final correct = controller.state == AnswerState.correct;
    final buttonText = correct ? 'سوال بعدی ›' : 'ادامه ›';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        FadeTransition(
          opacity: _btnFade,
          child: ScaleTransition(
            scale: _btnScale,
            child: PressSink(
              onTap: controller.next,
              borderRadius: 24,
              borderWidth: 1.6,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
              child: Text(
                buttonText,
                style: const TextStyle(fontFamily: AppTheme.sans, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
