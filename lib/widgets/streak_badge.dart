import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The 🔥 record / streak pill. Solid filled background:
/// green after a correct answer, red after a wrong one, ink otherwise.
/// Pulses (scale bump) whenever [value] changes.
class StreakBadge extends StatefulWidget {
  const StreakBadge({
    super.key,
    required this.label,
    required this.value,
    this.color = AppColors.ink,
  });

  final String label; // e.g. 'رکورد' or ''
  final String value; // Persian digits
  final Color color;

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant StreakBadge old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.label.isEmpty
        ? '🔥 ${widget.value}'
        : '🔥 ${widget.label} ${widget.value}';
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: AppTheme.sans,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
