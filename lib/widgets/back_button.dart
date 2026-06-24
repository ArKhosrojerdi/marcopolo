import 'package:flutter/material.dart';

import 'press_sink.dart';

/// Circular back button — sinks down on press (shadow collapses) via [PressSink],
/// matching the option cards' "stamp" feel. Sized to match the quiz screen's
/// exit button.
class BackStickerButton extends StatelessWidget {
  const BackStickerButton({super.key, required this.onTap});
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
      // RTL: back chevron points left ("‹")
      child: const Text('‹', style: TextStyle(fontSize: 24)),
    );
  }
}
