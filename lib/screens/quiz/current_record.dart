import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Current (per-mode) record, centered below the header. Pulses + flashes
/// green for one beat when the player just set a new record.
class CurrentRecord extends StatefulWidget {
  const CurrentRecord({super.key, required this.value, required this.beat});
  final int value;
  final bool beat;

  @override
  State<CurrentRecord> createState() => _CurrentRecordState();
}

class _CurrentRecordState extends State<CurrentRecord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 60),
  ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    if (widget.beat) _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(CurrentRecord old) {
    super.didUpdateWidget(old);
    if (widget.beat && !old.beat) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final active = widget.beat && _ctrl.isAnimating;
          final color = active ? AppColors.correct : AppColors.ink;
          final bg = active ? AppColors.correctBg : AppColors.postit;
          final borderColor = active ? AppColors.correct : AppColors.postitBorder;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: borderColor, width: 1.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🔥 رکورد ${toPersianDigits(widget.value)}',
              style: TextStyle(
                fontFamily: AppTheme.sans,
                fontSize: 12,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}
