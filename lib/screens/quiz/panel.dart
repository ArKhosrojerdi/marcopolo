import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Highlighted bordered panel with a hard offset shadow — the framed block used
/// behind the quiz prompt (currency/capital/neighbor) and the completion score.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.highlight,
        border: Border.all(color: AppColors.ink, width: 1.6),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
