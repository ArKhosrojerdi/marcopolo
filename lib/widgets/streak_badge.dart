import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The 🔥 record / streak pill. Border+text color shifts:
/// green after a correct answer, red after a wrong one, ink otherwise.
class StreakBadge extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final text = label.isEmpty ? '🔥 $value' : '🔥 $label $value';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: AppTheme.sans, fontSize: 12, color: color),
      ),
    );
  }
}
