import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Circular mute/unmute toggle — same sticker look & size as [BackStickerButton].
/// Icon only: speaker-on when sound is active, speaker-off when muted.
class MuteStickerButton extends StatefulWidget {
  const MuteStickerButton({super.key, required this.muted, required this.onTap});
  final bool muted;
  final VoidCallback onTap;

  @override
  State<MuteStickerButton> createState() => _MuteStickerButtonState();
}

class _MuteStickerButtonState extends State<MuteStickerButton> {
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
        child: Icon(
          widget.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          size: 22,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
