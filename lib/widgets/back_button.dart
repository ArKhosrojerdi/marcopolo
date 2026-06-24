import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/sound_service.dart';
import '../theme/app_theme.dart';

/// Circular back button — sinks down on press (shadow collapses), matching the
/// option cards' "stamp" feel. Sized to match the quiz screen's exit button.
class BackStickerButton extends StatefulWidget {
  const BackStickerButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  State<BackStickerButton> createState() => _BackStickerButtonState();
}

class _BackStickerButtonState extends State<BackStickerButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        HapticFeedback.lightImpact();
        SoundService.instance.playTap();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.ink, width: 1.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(0, _pressed ? 0 : 2),
              blurRadius: 0,
            ),
          ],
        ),
        // RTL: back chevron points left ("‹")
        child: const Text('‹', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
